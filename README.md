# MoonTraceGate

MoonTraceGate checks whether a candidate build exceeds timing budgets measured
from a baseline and a candidate Chrome Trace JSON export. It attributes own
time to nested duration events and reports the exact failing budget, which makes
it practical to gate changes on named phases such as parsing or code generation.

[中文说明](README.zh-CN.md) · Apache-2.0 · MoonBit core · Node CLI · JS backend

## Run the MVP

Use the MoonBit and Node.js versions in [toolchain.json](toolchain.json). From
the repository root run:

    node examples/demo.mjs

The command builds the release CLI and asserts four paths: allow, block,
reject an incomplete trace, and replay a newly recorded Node workload.
Synthetic fixtures give stable expected values. The measured workload varies
by machine; its self-comparison must always have a zero delta.

| Candidate | Expected decision |
| --- | --- |
| candidate-pass.json | Exit 0. Pipeline own time is 2,000 ns. |
| candidate-regression.json | Exit 1. Own time rises from 2,000 to 5,000 ns, above both budgets. |
| candidate-invalid.json | Exit 2. Reports the unclosed begin event on stderr. |

Run one fixture directly:

    moon run cmd/main --target js -- examples/baseline.json examples/candidate-pass.json examples/budgets.json

For real captures, replace the first two files with Chrome Trace JSON exports.
See [input and report details](docs/format.md). Generate a trace locally via
`node examples/capture.mjs capture.json` or run the public library sample
`moon run examples/library --target js`.

Current source version is 0.1.0. Until Mooncakes publication, use the source
checkout and `examples/library` to exercise the API.

## Verification

    node scripts/verify.mjs
    ./scripts/powershell-smoke.ps1

Verification rebuilds both CLI modes, runs unit tests and CLI scenarios, and
checks timing attribution with independent enumeration. Evidence and publication
state are recorded in [acceptance](docs/acceptance.md).
