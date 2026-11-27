# Changelog

## Unreleased

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
