import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {buildCli, checked, invoke, moonRun, root} from './tooling.mjs';
import {checkDemo, checkSeriesDemo} from '../examples/demo.mjs';
import {verifySeries} from './verify-series.mjs';

const receipt = path.join(root, '_build/verification-summary.json');
fs.mkdirSync(path.dirname(receipt), {recursive: true});
fs.rmSync(receipt, {force: true});
const toolchain = JSON.parse(fs.readFileSync(path.join(root, 'toolchain.json'), 'utf8'));
const version = moonRun(['version', '--all']);
assert.equal(version.match(/^moon (\S+)/m)?.[1], toolchain.moon);
assert.equal(version.match(/^moonc (\S+)/m)?.[1], toolchain.moonc);
assert.equal(process.versions.node, toolchain.node_tested);

const head = fs.existsSync(path.join(root, '.git')) ? checked('git', ['rev-parse', 'HEAD']).trim() : null;
function verifyCiCommit() {
  if (process.env.GITHUB_ACTIONS !== 'true') return;
  assert.equal(head, process.env.GITHUB_SHA);
  assert.equal(checked('git', ['rev-parse', 'HEAD']).trim(), head);
  assert.equal(checked('git', ['status', '--porcelain']).trim(), '');
}

function traceEvent(s) {
  return {ph: 'X', pid: 1, tid: s.lane, ts: s.start / 4, dur: (s.stop - s.start) / 4, name: s.name};
}

const metrics = ['total_ns', 'self_ns', 'max_ns'];

// Independent oracle. Rasterize short generated spans into 250 ns slots and
// charge each slot to its smallest containing span on that lane.
function slotOracle(spans) {
  const out = new Map();
  const lanes = new Set(spans.map(s => s.lane));
  for (const s of spans) {
    const stats = out.get(s.name) ?? {total_ns: 0, self_ns: 0, max_ns: 0};
    const duration = (s.stop - s.start) * 250;
    stats.total_ns += duration;
    stats.max_ns = Math.max(stats.max_ns, duration);
    out.set(s.name, stats);
  }
  for (const lane of lanes) {
    for (let tick = 0; tick < Math.max(...spans.map(s => s.stop)); tick++) {
      let owner;
      for (const s of spans) {
        if (s.lane !== lane || s.start > tick || tick >= s.stop) continue;
        if (!owner || s.stop - s.start <= owner.stop - owner.start) owner = s;
      }
      if (owner) out.get(owner.name).self_ns += 250;
    }
  }
  return out;
}

function budgetsFor(spans) {
  return [...new Set(spans.map(s => s.name))].flatMap(name =>
    metrics.map(metric => ({name, metric, max_growth_ns: 0})));
}

function checkAgainstOracle(cli, temp, spans, events, valid) {
  fs.writeFileSync(temp, JSON.stringify({traceEvents: events}));
  const r = invoke(cli, [temp, temp, '-'], JSON.stringify(budgetsFor(spans)));
  if (!valid) {
    assert.equal(r.status, 2, r.stderr);
    assert.equal(r.stdout, '');
    assert.match(r.stderr, /crossing duration spans/);
    return;
  }
  assert.equal(r.status, 0, r.stderr);
  const report = JSON.parse(r.stdout);
  const expected = slotOracle(spans);
  assert.equal(report.candidate_spans, spans.length);
  assert.equal(report.rules.length, expected.size * 3);
  for (const rule of report.rules) {
    const ns = expected.get(rule.name)[rule.metric];
    assert.equal(rule.baseline_ns, ns);
    assert.equal(rule.candidate_ns, ns);
    assert.equal(rule.delta_ns, 0);
    assert.deepEqual(rule.reasons, []);
  }
}

function verifyAttribution(cli, mode) {
  const temp = path.join(root, '_build', 'oracle-' + mode + '.json');
  const intervals = [];
  for (let start = 0; start < 4; start++) {
    for (let stop = start + 1; stop <= 4; stop++) {
      intervals.push({start, stop});
    }
  }
  let crossing = 0;
  for (const a of intervals) {
    for (const b of intervals) {
      const invalid = (a.start < b.start && b.start < a.stop && a.stop < b.stop) ||
        (b.start < a.start && a.start < b.stop && b.stop < a.stop);
      crossing += Number(invalid);
      const spans = [{...a, lane: 0, name: 'a'}, {...b, lane: 0, name: 'b'}];
      checkAgainstOracle(cli, temp, spans, spans.map(traceEvent), !invalid);
    }
  }
  for (let i = 0; i < 32; i++) {
    const name = (offset) => 'phase' + ((i >>> offset) & 3);
    const spans = [
      {lane: 0, start: 0, stop: 12, name: name(0)},
      {lane: 0, start: 1, stop: 4 + (i & 1), name: name(1)},
      {lane: 0, start: 2, stop: 3, name: name(2)},
      {lane: 0, start: 6, stop: 9, name: name(3)},
      {lane: 1, start: 2, stop: 7, name: name(4)},
      {lane: 1, start: 4, stop: 4, name: 'marker'},
    ];
    const [parent, ...rest] = spans;
    const start = traceEvent(parent);
    const events = [
      {ph: 'E', pid: 1, tid: 0, ts: 3},
      ...rest.map(traceEvent).reverse(),
      {ph: 'B', pid: 1, tid: 0, ts: start.ts, name: parent.name},
    ];
    checkAgainstOracle(cli, temp, spans, events, true);
  }
  console.log('PASS ' + mode + ': 132 independently checked interval models (' + crossing + ' crossing errors)');
  return {intervalModels: 132, crossing};
}

function verifyBoundaries(cli, mode) {
  const baseline = 'examples/baseline.json';
  const rules = 'examples/budgets.json';
  const event = {pid: 1, tid: 0, name: 'a', ph: 'X', ts: 0, dur: 1};
  const tiny = [{name: 'a', metric: 'max_ns', limit_ns: 1000}];
  const text = value => JSON.stringify(value);
  const invalid = [
    ['{"traceEvents":[],"traceEvents":[]}', /invalid_json/],
    [Buffer.from([0xff]), /io: candidate/],
    ['['.repeat(17) + ']'.repeat(17), /limit_exceeded/],
    [' '.repeat(1048577), /input exceeds/],
    [text(Array(4097).fill({ph: 'M'})), /more than 4096/],
    [text([{...event, dur: -1}]), /dur must be bounded/],
    [text([{...event, tid: 1.5}]), /tid must be a bounded/],
    [text([{...event, ph: 'E'}]), /no matching begin/],
    [text([{...event, ph: 'B'}, {...event, ph: 'E', ts: 1, name: 'wrong'}]), /label differs/],
    [text([{...event, ph: 'B'}, {...event, ph: 'E', ts: 1, tid: 2}]), /unclosed begin/],
  ];
  for (const [input, message] of invalid) {
    const out = invoke(cli, [baseline, '-', rules], input);
    assert.equal(out.status, 2, out.stderr);
    assert.equal(out.stdout, '');
    assert.match(out.stderr, message);
  }
  const trace = path.join(root, '_build', 'limit-' + mode + '.json');
  const extra = Array(4095).fill({ph: 'M'});
  fs.writeFileSync(trace, '\ufeff' + text([event, ...extra]));
  const atLimit = invoke(cli, [baseline, trace, '-'], text(tiny));
  assert.equal(atLimit.status, 0, atLimit.stderr);
  assert.equal(JSON.parse(atLimit.stdout).candidate_skipped, 4095);
  const added = invoke(cli, [baseline, trace, '-'], text([{...tiny[0], max_growth_ns: 0}]));
  assert.equal(added.status, 1);
  assert.deepEqual(JSON.parse(added.stdout).rules[0].reasons, ['missing_baseline']);
  const removed = invoke(cli, [trace, baseline, '-'], text(tiny));
  assert.equal(removed.status, 1);
  assert.deepEqual(JSON.parse(removed.stdout).rules[0].reasons, ['missing_candidate']);
  for (const bad of [[], [tiny[0], tiny[0]], [{...tiny[0], limit_ns: 1.5}], [{...tiny[0], extra: true}]]) {
    const r = invoke(cli, [baseline, trace, '-'], text(bad));
    assert.equal(r.status, 2);
    assert.equal(r.stdout, '');
  }
  assert.equal(invoke(cli, ['-', '-', rules], '').status, 2);
  assert.equal(invoke(cli, ['--version'], '').stdout.trim(), '0.2.4');
  assert.match(invoke(cli, ['--help'], '').stdout, /moon-tracegate/);
  const fd = fs.openSync(path.join(root, 'moon.mod'), 'r');
  try {
    assert.equal(invokeWithClosedOutput(cli, fd), 2);
  } finally {
    fs.closeSync(fd);
  }
  return {traceErrors: invalid.length, ruleErrors: 4, eventCap: 4096};
}

import {run} from './tooling.mjs';
function invokeWithClosedOutput(cli, fd) {
  return run(process.execPath, [cli, '--version'], {stdio: ['ignore', fd, 'pipe']}).status;
}

verifyCiCommit();
moonRun(['fmt', '--check']);
moonRun(['check', '--target', 'js', '--deny-warn']);
moonRun(['info', '--target', 'js']);
const reports = [];
for (const mode of ['debug', 'release']) {
  const flag = mode === 'release' ? ['--release'] : [];
  const unitTests = moonRun(['test', '--target', 'js', '--deny-warn', ...flag]).trim();
  console.log(unitTests);
  assert.match(moonRun(['run', 'examples/library', '--target', 'js', '--deny-warn', ...flag]), /PASS public API/);
  const cli = buildCli(mode);
  checkDemo(cli);
  checkSeriesDemo(cli);
  reports.push({
    mode, unitTests,
    cliSha256: createHash('sha256').update(fs.readFileSync(cli)).digest('hex'),
    ...verifyAttribution(cli, mode),
    ...verifyBoundaries(cli, mode),
    ...verifySeries(cli, mode),
  });
}
verifyCiCommit();
const summary = {status: 'passed', sourceCommit: head, recordedAt: new Date().toISOString(), toolchain, reports};
fs.writeFileSync(receipt + '.tmp', JSON.stringify(summary, null, 2) + '\n');
fs.renameSync(receipt + '.tmp', receipt);
