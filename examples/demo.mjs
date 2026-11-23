import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {buildCli, checked, invoke} from '../scripts/tooling.mjs';

export function checkDemo(cli) {
  const runExample = name => invoke(cli, [
    'examples/baseline.json', 'examples/' + name + '.json', 'examples/budgets.json',
  ]);

  const pass = runExample('candidate-pass');
  assert.equal(pass.status, 0, pass.stderr);
  const allowed = JSON.parse(pass.stdout);
  assert.equal(allowed.status, 'pass');
  assert.equal(allowed.rules[0].candidate_ns, 2000);
  assert.equal(allowed.baseline_skipped, 1);
  console.log('PASS stable build: pipeline self time 2000 ns, exit 0');

  const regression = runExample('candidate-regression');
  assert.equal(regression.status, 1, regression.stderr);
  const blocked = JSON.parse(regression.stdout);
  assert.equal(blocked.status, 'fail');
  assert.equal(blocked.rules[0].baseline_ns, 2000);
  assert.equal(blocked.rules[0].candidate_ns, 5000);
  assert.equal(blocked.rules[0].delta_ns, 3000);
  assert.deepEqual(blocked.rules[0].reasons, ['growth_limit', 'absolute_limit']);
  console.log('PASS regression caught: pipeline self time 2000 -> 5000 ns, exit 1');

  const invalid = runExample('candidate-invalid');
  assert.equal(invalid.status, 2);
  assert.equal(invalid.stdout, '');
  assert.match(invalid.stderr, /candidate: event 0: unclosed begin/);
  console.log('PASS incomplete trace rejected: exit 2, empty stdout');

  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'moontracegate-demo-'));
  try {
    const trace = path.join(temp, 'captured trace.json');
    checked(process.execPath, ['examples/capture.mjs', trace]);
    const rule = [{cat: 'demo', name: 'prepare', metric: 'self_ns', max_growth_ns: 0}];
    const run = invoke(cli, [trace, trace, '-'], JSON.stringify(rule));
    assert.equal(run.status, 0, run.stderr);
    const report = JSON.parse(run.stdout);
    assert.equal(report.rules[0].delta_ns, 0);
    assert.equal(report.candidate_spans, 4);
    console.log('PASS real instrumented Node trace: four spans, self-comparison delta 0 ns');
  } finally {
    for (const file of fs.readdirSync(temp)) fs.unlinkSync(path.join(temp, file));
    fs.rmdirSync(temp);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  checkDemo(buildCli('release'));
}
