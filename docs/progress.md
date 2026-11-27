# MoonTraceGate 0.2.4 published — 2026-11-28

Published from `cff49cd1c3f03693b5096ee112b1c8cbfe8ed241`. Reports for 3,500 nested duration and marker events and 15 metric rules were byte-identical across the two CLI builds.
See [acceptance](acceptance.md) for the verified ZIP and exact-version consumer.

# MoonTraceGate 0.2.3 published — 2026-11-27

Published from `16d1f4c5bf1fb6711a5a14db286905a311a3fd2c`. Complete duration events need only the attribution sort. The CLI report matched the previous release byte for byte for 3,500 shuffled complete events and a mixed B/E/X trace.
The exact public package installs and passes both modes. See
[acceptance](acceptance.md) for CI and registry receipts.

# MoonTraceGate 0.2.2 published — 2026-11-27

Published from `2a25a1f34d3ac504612a201ae7b509cc13325c67`. The public ZIP and exact-version install
were verified. See [acceptance](acceptance.md) for release evidence.

# Local series memory optimization — 2026-11-27

Series profiling collects each rule's measurements immediately after profiling
a capture. The series retains the output measurements while the complete
profile is local to one iteration. A regression covers unequal series lengths,
rule and sample ordering, and a missing measurement.

Both local builds passed 14 unit tests, 132 interval models, 40 independent
percentile comparisons and six invalid series cases. PowerShell smoke passed.
The 32-by-32 capture comparison used 112 groups per capture and produced
byte-identical CLI reports. Across nine alternating runs on this Windows
machine, median peak RSS was 78.57 MiB before and 78.10 MiB after.

# Local timing precision fix — 2026-11-26

Epoch-sized fractional timestamps now convert from the original JSON decimal
to picoseconds. The old CLI reported zero for a 1 ns interval across a rounding
boundary and passed a zero budget. The revised CLI reports 1 ns and exits 1 for
that budget. Regressions also cover equivalent B/E events and decimal spellings
just outside the timestamp domain.

Debug and release each passed 13 units, 132 interval models, 40 independent
percentile cases and six invalid series cases. PowerShell smoke passed. A
separate 96-interval CLI check matched a BigInt reference for exact decimal
and exponent spellings at ordinary and large timestamps.

# MoonTraceGate 0.2.1 published - 2026-11-26

Published from 9b4cc8af90c03f6db9bf0697480fc1dcd9836fcb. The public registry download
and exact-version consumer were verified. See [acceptance](acceptance.md)
for CI, archive and installation evidence.

# Local validation fix — 2026-11-26

Budget fields, series percentiles and lane IDs validate exact JSON integers
before accepting their decoded values. The 0.2.0 CLI accepted
1.00000000000000001 as the growth limit 1. The revised release-mode CLI
returns invalid_input with exit 2 and empty stdout. Exact exponent forms,
integral decimals and signed zero have regression coverage.

The local debug and release verifiers each passed 11 units, 132 interval models,
40 independent percentile comparisons and six invalid series cases. PowerShell
smoke passed for stdin, absolute paths and series mode.


# Delivery state

Version 0.2.0 is published as JingLan0v0/tracegate from `b1603accb19cefcf8473e97c0aeaf643f4903a75`.
The revision corrected fractional endpoints and added multi-run percentile
budgets, sample reporting and verification. Both operating-system CI jobs,
the actual package extraction and the fresh registry installation passed.
See acceptance.md and publication-0.2.0.json for exact evidence.
The previous 0.1.0 release remains recorded in acceptance.md.

The revised proposal is available on the user's desktop.
