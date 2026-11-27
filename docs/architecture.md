# Attribution and validation

Normalize synchronous events to integer picosecond (ps) timestamps. For text
input, scale the original decimal timestamp or duration and round half a
picosecond up. For programmatic JSON numbers without a decimal spelling,
convert whole microseconds separately from the decoded fractional part.
Add complete-event duration in integer picoseconds,
then sort by process, thread, timestamp and index. Preserve picosecond
endpoints through structural validation. Pair begin and end using a stack on each
track. Complete events contribute spans directly. If the capture uses only
complete events, skip the pairing sort. Then sort complete spans by
track, ascending start, descending end and original index. A stack retains
only the spans that can contain the next positive interval. Round both endpoints
to nanoseconds when adding a duration to a metric. A child ending
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
In series mode, process each capture in input order. Retain only the selected
measurement for each rule and sample. Each capture's complete profile can be
released after its measurements have been recorded.
The CLI interprets a failing budget as a valid report and exits 1. Input errors
abort before emitting any report. Core analysis and report construction live
in MoonBit. Node supplies file/process I/O and independent test tooling.
