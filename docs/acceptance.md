# Local MVP acceptance evidence

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

The project is awaiting the owner's public GitHub repository. The configured
Windows/Ubuntu CI and Mooncakes publication will be verified at upload.
