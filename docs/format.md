# Input and result contract

The CLI accepts three JSON files: baseline, candidate, and rules. Use a single
hyphen as at most one file to read stdin. A trace may be the event array itself
or an object with a traceEvents array. Additional trace metadata is ignored.

## Trace events

| Field | Contract |
| --- | --- |
| ph | B opens, E closes one span per process/thread, X specifies a complete duration. Other phase strings are counted as skipped. |
| pid, tid | Nonnegative integers up to 2,147,483,647 for B, E and X. |
| ts | Nonnegative microseconds up to 10^12. Endpoints are rounded to nearest ns for metrics. Use relative timestamps for larger origins. |
| dur | X duration in microseconds, up to 10^9, added to the start before endpoint rounding. B/E spans have the same duration bound. |
| cat, name | Exact case-sensitive grouping key. Missing cat becomes an empty string. Names on B/X are required and nonempty. Optional nonempty E labels must match the open span. Both strings are capped at 128 UTF-16 units. |

Events on a track are ordered by source timestamp and original source order
for ties. Closed spans on one track must nest or be disjoint. Same starts put
longer spans first; identical positive spans nest by original source order.
Zero-length spans count toward their group and contribute zero time. They do
not alter nonzero containment. A span is half-open, so touching spans can be
siblings. Cross-thread boundaries never subtract time from each other.
Crossing or unpaired spans produce an error before rounding. Async/flow and counter semantics
are outside this duration subset. A name missing from supported events fails
its budget check when the name is required.

## Budget and report

Rules are an array of 1–64 objects, each with cat (optional), name, metric and
at least one of limit_ns or max_growth_ns. Duplicated category/name/metric keys,
unknown fields and fractional/negative budgets are errors. Limits are inclusive
nonnegative integers no greater than 2^53−1. Metric total_ns sums full durations,
self_ns sums durations less direct same-track child time, and max_ns selects
the longest full duration. Groups combine tracks. Inclusive totals may count
nested work twice. These are attributed wall-clock intervals, not CPU samples
or a process-wide critical path.

The report returns baseline, candidate, signed delta, applicable limits and a
reasons array per rule. Absent measurements are null. A missing candidate always
fails. A missing baseline fails when a growth limit requires a comparison.
A new span can pass an absolute-only rule. Supplying both limits requires both
to pass. Exit 0 is a passing report, 1 is a valid failing report, and 2 is an
input or I/O error with stderr diagnostics. A stdout write failure may leave
partial output and exits 2.

Each CLI file is capped at 1 MiB bytes, with strict UTF-8 and optional BOM. JSON
text parsing also caps UTF-16 units to 1 Mi, nesting to 16, raw string scanner to
256 characters and outside-string non-whitespace scanner to 200,000. Duplicate
keys are rejected. Each trace contains at most 4,096 events. The library profile
entry takes parsed JSON and applies the event limits independently. No network
access is performed by the CLI.
