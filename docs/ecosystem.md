# Related tools reviewed on November 23, 2026

| Tool | Observed focus | MoonTraceGate scope |
| --- | --- | --- |
| Yu-zh/tracing | Logging and Chrome trace event generation | Consume exported duration traces and apply budgets |
| mizchi/moon-pprof | Profiling across backends and V8 profiler/pprof conversion | Attribute synchronous duration intervals, compare named metrics and report gate results |
| Perfetto | Trace ingestion, UI and general query analysis | Small offline MoonBit library and CI command with explicit input, limits and status |

Searches covered Mooncakes and GitHub variants of tracing, Chrome trace,
profiling and budget. These are scoped differences, not a claim that the
method is new or that no other tool can implement a similar budget.
References: https://mooncakes.io/docs/Yu-zh/tracing@0.1.0 ,
https://github.com/mizchi/moon-pprof ,
https://perfetto.dev/docs/getting-started/other-formats .
