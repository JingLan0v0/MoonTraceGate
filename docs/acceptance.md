# Acceptance evidence

## Mooncakes 0.1.0

Published from `54e05f09a6a44460a6db0f6834286007561889cc` at 2026-11-23T13:23:01.429050+00:00.
The [release CI run](https://github.com/JingLan0v0/MoonTraceGate/actions/runs/45183075865)
succeeded on Windows and Ubuntu for this exact SHA. The repository is public.

Mooncakes accepted the preflight (202) and formal upload (200). The 39 files in
the release archive matched Git source after newline normalization. Full checks
in a separate extraction completed at 2026-11-23T13:22:28.131Z. Debug and
release each passed 3 unit tests, 132 independent interval models, the four-case
demo and public API example, invalid trace/rule and transport tests. PowerShell
passed as well.

An independent project with a fresh cache installed version 0.1.0 directly
from the registry. Debug and release confirmed nested self time and budget
decisions. All 39 installed files matched the verified ZIP. SHA-256:
`098a9801d22dcca6e63b809e6c0756ce6d644b5104bb3a01d7977efbfb4cc1a3`.

[Registry version](https://mooncakes.io/docs/JingLan0v0/tracegate@0.1.0) ·
[Machine-readable receipt](publication-0.1.0.json)

## Original local delivery

Checked on November 23, 2026 with the pinned MoonBit and Node.js toolchain.
The clean Git source archive is from `7415b75b5c4e71f2d88c45395e482ef1656ed9fa`. All 42 tracked files
matched the archive. SHA-256 is `5f23a46ba104dfe215645ff107368d737be6b682986fd4697e3165a6c8688c03`.
The extracted verifier completed at 2026-11-23T13:17:53.850Z.

- Debug and release each passed three core unit tests and 132 independently
  checked interval models, including 10 crossing-trace errors.
- Each mode ran the public library example, three deterministic gate outcomes
  and capture/replay of a four-span Node workload.
- Each mode checked 10 invalid trace or transport cases, four invalid rules,
  missing measurements, the 4,096-event inclusive cap, exit codes and
  stdout failure. PowerShell verified the wrapper, stdin and absolute paths.
- Reproduce using `node examples/demo.mjs` and `node scripts/verify.mjs`.
  The local archive and machine-readable evidence are in the ignored _build
  directory. This archive is for source reproduction.
