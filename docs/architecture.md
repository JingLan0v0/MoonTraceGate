# Attribution and validation

Normalize synchronous duration events to nanoseconds. First sort by process,
thread, timestamp and original index. Pair begin and end using a stack on each
track. Complete events contribute spans directly. Then sort complete spans by
track, ascending start, descending end and original index. A stack retains
only the spans that can contain the next positive interval. A child ending
past the parent boundary is a crossing trace error.

The direct positive child intervals of a node in this containment tree are
disjoint. Subtracting the sum of their durations once gives the parent's own
time. Grandchildren contribute to the child interval rather than receiving a
second subtraction from the parent. Accumulate per exact category/name key
and keep maxima. Zero-duration markers cannot remove time. The two sorts
take O(n log n) time and all arrays/maps are O(n). Each group total is bounded
by 4096 * 10^12 ns and serialized without losing integer precision.

Comparison reports one result per requested metric key. It applies inclusive
absolute and delta bounds and distinguishes a missing measurement from zero.
The CLI interprets a failing budget as a valid report and exits 1. Input errors
abort before emitting any report. Core analysis and report construction live
in MoonBit. Node supplies file/process I/O and independent test tooling.
