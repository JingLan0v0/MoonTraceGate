import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

export const root = path.resolve(import.meta.dirname, '..');
const exe = process.platform === 'win32' ? 'moon.exe' : 'moon';
const installations = [
  process.env.MOON_HOME,
  path.resolve(root, '../.tools/moonstn-toolchain'),
  path.resolve(root, '../MoonBit黑客松/.tools/moonstn-toolchain'),
].filter(Boolean);
const installation = installations.find(dir => fs.existsSync(path.join(dir, 'bin', exe)));
if (installation) process.env.MOON_HOME = installation;
const moon = process.env.MOON_BIN || (installation ? path.join(installation, 'bin', exe) : exe);

export function run(command, args, options = {}) {
  const r = spawnSync(command, args, {
    cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 4 * 1024 * 1024, ...options,
  });
  assert.ifError(r.error);
  assert.equal(r.signal, null);
  return r;
}

export function checked(command, args) {
  const r = run(command, args);
  assert.equal(r.status, 0, r.stderr || r.stdout);
  return r.stdout;
}

export function moonRun(args) {
  return checked(moon, args);
}

export function buildCli(mode) {
  const js = path.join(root, '_build/js', mode, 'build/cmd/main/main.js');
  fs.rmSync(js, {force: true});
  const flag = mode === 'release' ? ['--release'] : [];
  moonRun(['build', 'cmd/main', '--target', 'js', '--deny-warn', ...flag]);
  assert(fs.statSync(js).size > 0, 'Expected a freshly built CLI');
  return js;
}

export function invoke(cli, args, input) {
  return run(process.execPath, ['--max-old-space-size=192', cli, ...args], {
    input, timeout: 15000,
  });
}
