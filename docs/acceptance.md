# Acceptance evidence

## Mooncakes 0.2.2 — 2026-11-27

Release source: `2a25a1f34d3ac504612a201ae7b509cc13325c67`. [GitHub Actions](https://github.com/JingLan0v0/MoonTraceGate/actions/runs/45955479778) passed
on Windows and Ubuntu for this commit. The archive contained 51
files matching the source. Full Debug and Release verification and the
PowerShell smoke test passed after clean extraction.

Mooncakes preflight returned 202 Accepted and publication returned 200 OK.
The [version page](https://mooncakes.io/docs/JingLan0v0/tracegate@0.2.2) returned HTTP 200.
The [public ZIP](https://download.mooncakes.io/user/JingLan0v0/tracegate/0.2.2.zip) and the tested publisher ZIP share SHA-256
`e55e27c24e969ede17576f5bdd79df42b4d2684b7982d93d0ec891a75f02315a`. The public metadata records 2026-11-27T15:01:29.6705570+08:00.

A clean consumer installed `JingLan0v0/tracegate@0.2.2` from Mooncakes without a workspace
override or registry credentials. All 51 installed files
matched the ZIP byte for byte. Debug and Release passed. The consumer exercised unequal series sizes, the 1 ns timing boundary and a zero budget.

## Mooncakes 0.2.1 - 2026-11-26

Release source: 9b4cc8af90c03f6db9bf0697480fc1dcd9836fcb. The [GitHub Actions run](https://github.com/JingLan0v0/MoonTraceGate/actions/runs/45763268591) passed on
Windows and Ubuntu for that commit. Full debug and release verification
and PowerShell smoke passed on a clean extraction of the publisher ZIP.

Mooncakes returned 202 Accepted for preflight and 200 OK for publication.
The [public version page](https://mooncakes.io/docs/JingLan0v0/tracegate@0.2.1) returned HTTP 200. The
[registry ZIP](https://download.mooncakes.io/user/JingLan0v0/tracegate/0.2.1.zip) SHA-256 equals the tested
publisher ZIP and the public metadata checksum:
05a5efca778d9be79dfd455e6c93a1253d4060a36a36f0ebe46cc0dc3db7bd4a

An independent consumer installed JingLan0v0/tracegate@0.2.1 from the public
registry using a fresh cache without credentials or a workspace override.
All 51 installed files matched the publisher ZIP byte for byte.
Both installed builds accepted an exact integral exponent and rejected a fractional budget that rounded to an integer in 0.2.0.
Registry publication timestamp: 11/26/2026 14:16:11.

## Mooncakes 0.2.0

Published from `b1603accb19cefcf8473e97c0aeaf643f4903a75` at 2026-11-25T10:11:02.444713+00:00.
[Release CI](https://github.com/JingLan0v0/MoonTraceGate/actions/runs/45592206681)
succeeded on Windows and Ubuntu for this SHA. Actual archive extraction
verification completed at 2026-11-25T10:10:34.805Z. Each mode passed 9 unit
tests, 132 independent interval models and 40 independent percentile
comparisons. Both builds also passed all demos and malformed input checks.
PowerShell verified stdin and absolute paths in both single and series mode.

The 0.1.0 output matched byte for byte for the three previous CLI fixtures,
including the diagnostics and exit codes. Fractional regression tests
reproduced inconsistent X and B/E metrics and hidden invalid intervals before
the fixes. A separate test reproduced a false crossing from decimal addition.
The fixed implementation validates integer picosecond endpoints and rounds
for measurement afterward.

Preflight returned `202 Accepted` and publication returned `200 OK`. The
49-file publisher ZIP matched the Git source after newline normalization.
The public registry ZIP and all 49 files installed into a fresh consumer
matched it. SHA-256 is `6f4cf297df2ea3f4acd319ab9e4ec27065bb6ae90dd532e101e29fd00b3b67e3`. The exact-version consumer verified
fractional endpoint rounding and multi-run p95 outcomes in debug and release.

[Registry version](https://mooncakes.io/docs/JingLan0v0/tracegate@0.2.0) ·
[Machine-readable release receipt](publication-0.2.0.json)

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
