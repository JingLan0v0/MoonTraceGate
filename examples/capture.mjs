import fs from 'node:fs';
import assert from 'node:assert/strict';
import {performance} from 'node:perf_hooks';

// Small, real instrumented data preparation task. Timestamp units match Chrome JSON.
const origin = performance.now();
const timestamp = () => Math.round((performance.now() - origin) * 1000 * 1000) / 1000;
const traceEvents = [];
const event = (ph, name, ts, extra = {}) => {
  traceEvents.push({ph, name, ts, cat: 'demo', pid: process.pid, tid: 0, ...extra});
};
function measure(name, action) {
  const start = timestamp();
  const value = action();
  const stop = timestamp();
  event('X', name, start, {dur: (Math.round(stop * 1000) - Math.round(start * 1000)) / 1000});
  return value;
}

const data = JSON.stringify(Array.from({length: 8192}, (_, id) => ({id, active: id % 3 === 0})));
event('B', 'prepare', timestamp());
const parsed = measure('parse', () => JSON.parse(data));
const selected = measure('filter', () => parsed.filter(row => row.active));
const encoded = measure('serialize', () => JSON.stringify(selected));
event('E', 'prepare', timestamp());
assert.equal(JSON.parse(encoded).length, 2731);
const output = JSON.stringify({traceEvents}, null, 2) + '\n';
if (process.argv[2]) fs.writeFileSync(process.argv[2], output, {flag: 'wx'});
else process.stdout.write(output);
