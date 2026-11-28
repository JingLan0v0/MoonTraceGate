///|
fn measure_samples(
  input : Json,
  label : String,
  rules : Array[Rule],
) -> (Array[Array[Int64?]], Int32) raise TraceError {
  guard input is Array(samples) &&
    samples.length() >= 3 &&
    samples.length() <= 32 else {
    raise TraceError(
      "invalid_input",
      label + " must be an array of 3..32 traces",
    )
  }
  let measurements : Array[Array[Int64?]] = rules.map(_ => [])
  for i, trace in samples {
    let captured = profile(trace) catch {
      TraceError(code, detail) =>
        raise TraceError(
          code,
          label + " sample " + (i + 1).to_string() + ": " + detail,
        )
    }
    for index, rule in rules {
      measurements[index].push(rule_measurement(captured, rule))
    }
  }
  (measurements, samples.length())
}

///|
fn nearest_rank(samples : Array[Int64?], percentile : Int32) -> Int64? {
  let count = samples.length()
  let rank = (percentile * count + 99) / 100
  if rank == 1 || rank == count {
    guard samples[0] is Some(first) else { return None }
    let mut extreme = first
    for i in 1..<count {
      guard samples[i] is Some(ns) else { return None }
      extreme = if rank == 1 { extreme.min(ns) } else { extreme.max(ns) }
    }
    return Some(extreme)
  }
  let sorted : Array[Int64] = []
  for sample in samples {
    match sample {
      Some(ns) => sorted.push(ns)
      None => return None
    }
  }
  sorted.sort()
  Some(sorted[rank - 1])
}

///|
/// Compare 3..32 trace samples on each side using a nearest-rank percentile.
/// Rules apply to per-sample measurements. Missing required groups are not
/// dropped from the distribution, and the result retains each input sample.
pub fn check_series(
  baseline : Json,
  candidate : Json,
  policy : Json,
) -> Json raise TraceError {
  guard policy is Object(options) else {
    raise TraceError("invalid_input", "series policy must be an object")
  }
  for key in options.keys() {
    if key != "percentile" && key != "rules" {
      raise TraceError("invalid_input", "unknown series policy field: " + key)
    }
  }
  let pct = match options.get("percentile") {
    None => 50
    Some(value) => integer(value, "percentile", 100.0).to_int()
  }
  if pct == 0 {
    raise TraceError("invalid_input", "percentile must be in 1..100")
  }
  let rules = read_rules(required(options, "rules"))
  let (previous, baseline_count) = measure_samples(baseline, "baseline", rules)
  let (current, candidate_count) = measure_samples(
    candidate, "candidate", rules,
  )
  let mut passed = true
  let reports = rules.mapi((index, rule) => {
    let base_samples = previous[index]
    let next_samples = current[index]
    let (record, ok) = budget_result(
      rule,
      nearest_rank(base_samples, pct),
      nearest_rank(next_samples, pct),
    )
    record["baseline_samples_ns"] = Json::array(base_samples.map(number))
    record["candidate_samples_ns"] = Json::array(next_samples.map(number))
    passed = passed && ok
    Json::object(record)
  })
  Json::object(
    Map([
      ("status", Json::string(if passed { "pass" } else { "fail" })),
      ("percentile", Json::number(pct.to_double())),
      ("baseline_sample_count", Json::number(baseline_count.to_double())),
      ("candidate_sample_count", Json::number(candidate_count.to_double())),
      ("rules", Json::array(reports)),
    ]),
  )
}
