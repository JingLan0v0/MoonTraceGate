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
