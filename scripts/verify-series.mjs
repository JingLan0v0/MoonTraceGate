import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {invoke, root} from './tooling.mjs';

// Find the smallest value whose cumulative count reaches the percentile.
// This oracle does not sort or reuse the implementation's rank formula.
function percentileAt(values, percentile) {
  return Math.min(...values.filter(value =>
    values.filter(sample => sample <= value).length * 100 >= percentile * values.length));
}

const known = (values) => values.map(ns => [{
  ph: 'X', name: 'work', pid: 1, tid: 1, ts: 0, dur: ns / 1000,
}]);

export function verifySeries(cli, mode) {
  const prev = path.join(root, '_build', 'series-baseline-' + mode + '.json');
  const next = path.join(root, '_build', 'series-candidate-' + mode + '.json');
  const args = ['--series', prev, next, '-'];
  const write = (dest, value) => fs.writeFileSync(dest, JSON.stringify(value));
  let seed = 47215;
  const draw = (limit) => {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return Math.floor(seed / 4294967296 * limit);
  };
  const check = (a, b, p, limit, growth) => {
    write(prev, known(a));
    write(next, known(b));
    const policy = {percentile: p, rules: [{name: 'work', metric: 'max_ns', limit_ns: limit, max_growth_ns: growth}]};
    const expectedBase = percentileAt(a, p);
    const expectedCurrent = percentileAt(b, p);
    const delta = expectedCurrent - expectedBase;
    const reasons = [];
    if (delta > growth) reasons.push('growth_limit');
    if (expectedCurrent > limit) reasons.push('absolute_limit');
    const r = invoke(cli, args, JSON.stringify(policy));
    assert.equal(r.status, reasons.length ? 1 : 0, r.stderr);
    const report = JSON.parse(r.stdout);
    assert.equal(report.percentile, p);
    assert.equal(report.baseline_sample_count, a.length);
    assert.equal(report.candidate_sample_count, b.length);
    const rule = report.rules[0];
    assert.equal(rule.baseline_ns, expectedBase);
    assert.equal(rule.candidate_ns, expectedCurrent);
    assert.equal(rule.delta_ns, delta);
    assert.deepEqual(rule.baseline_samples_ns, a);
    assert.deepEqual(rule.candidate_samples_ns, b);
    assert.deepEqual(rule.reasons, reasons);
  };
  check(Array(20).fill(1), [...Array(19).fill(1), 999], 95, 1, 0);
  check([0, 0, 0], [0, 0, 0], 100, 0, 0);
  check([3, 2, 1, 0], [4, 3, 2, 1], 50, 2, 1);
  check(Array(32).fill(14), Array(32).fill(13), 100, 13, 0);
  const percentiles = [1, 25, 50, 75, 95, 100];
  for (let i = 0; i < 36; i++) {
    const a = Array.from({length: 3 + draw(30)}, () => 10 * draw(23));
    const b = Array.from({length: 3 + draw(30)}, () => 10 * draw(23));
    check(a, b, percentiles[i % percentiles.length], draw(220), draw(80));
  }
  const policy = {rules: [{name: 'work', metric: 'total_ns', max_growth_ns: 5}]};
  const failInput = (message, settings = policy) => {
    const r = invoke(cli, args, JSON.stringify(settings));
    assert.equal(r.status, 2, r.stderr);
    assert.equal(r.stdout, '');
    assert.match(r.stderr, message);
  };
  write(prev, known([1, 2]));
  write(next, known([1, 2, 3]));
  failInput(/baseline must be an array of 3[.][.]32/);
  write(prev, known([1, 2, 3]));
  write(next, known(Array(33).fill(1)));
  failInput(/candidate must be an array of 3[.][.]32/);
  write(next, [known([1])[0], [{ph:'E',pid:1,tid:1,ts:1}], []]);
  failInput(/candidate sample 2: event 0: end has no matching begin/);
  write(next, known([1, 2, 3]));
  failInput(/percentile/, {...policy, percentile: 101});
  failInput(/percentile/, {...policy, percentile: 0});
  failInput(/unknown series policy field/, {...policy, extra: true});
  console.log('PASS ' + mode + ': 40 independent percentile comparisons and 6 invalid series cases');
  return {seriesComparisons: 40, invalidSeriesCases: 6};
}
