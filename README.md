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

The command builds the release CLI and asserts the single-run paths: allow, block,
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

Install the verified [Mooncakes 0.2.5 release](https://mooncakes.io/docs/JingLan0v0/tracegate@0.2.5)
in your MoonBit project with:

    moon add JingLan0v0/tracegate@0.2.5

Import `JingLan0v0/tracegate` in `moon.pkg`. The source checkout includes
`examples/library` as a runnable starting point.

## Multiple captures

Version 0.2.0 compares 3 to 32 captures per side. Each rule measures every
capture, then compares nearest-rank percentiles. The report preserves the
individual measurements so a missing event or a tail spike is visible.

    moon run cmd/main --target js -- --series examples/series-baseline.json examples/series-candidate.json examples/series-p50.json

Run the same command with series-p95.json to block the spike in this
fixture. The main demo exercises both policies, missing samples and a
three-capture run of the real Node workload. See [series semantics](docs/format.md#multi-run-gate).

## Verification

    node scripts/verify.mjs
    ./scripts/powershell-smoke.ps1

Verification rebuilds both CLI modes, runs unit tests and CLI scenarios, and
checks timing attribution with independent enumeration. Evidence and publication
state are recorded in [acceptance](docs/acceptance.md).
