# Changelog

## 0.2.4 — 2026-11-28

- Reuse each span duration for its own report and its enclosing span.

## 0.2.3 — 2026-11-27

- Skip the pairing sort for captures that contain only complete duration events.

## 0.2.2 — 2026-11-27

- Collect series budget measurements one capture at a time to avoid retaining all profiles.

- Preserve picosecond precision for large timestamps in JSON trace files.

## 0.2.1 — 2026-11-26

- Reject fractional JSON spellings that round to an integer in budget limits,
  series percentiles and trace lane IDs.

## 0.2.0

- Compare multiple trace captures by nearest-rank percentile. Retain all
  observations and block missing required measurements.
- Normalize timestamps to integer picoseconds for event ordering and exact
  endpoint addition, then round endpoints for nanosecond metrics.
- Add a captured multi-run demo, an independent percentile oracle and
  regressions for fractional trace edges.

## 0.1.0

- Add synchronous Chrome Trace attribution, single-run budgets and CLI.
