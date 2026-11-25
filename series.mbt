///|
fn profile_samples(
  input : Json,
  label : String,
) -> Array[Profile] raise TraceError {
  guard input is Array(samples) &&
    samples.length() >= 3 &&
    samples.length() <= 32 else {
    raise TraceError(
      "invalid_input",
      label + " must be an array of 3..32 traces",
    )
  }
  samples.mapi((i, trace) => {
    profile(trace) catch {
      TraceError(code, detail) =>
        raise TraceError(
          code,
          label + " sample " + (i + 1).to_string() + ": " + detail,
        )
    }
  })
}

///|
fn nearest_rank(samples : Array[Int64?], percentile : Int32) -> Int64? {
  let sorted : Array[Int64] = []
  for sample in samples {
    match sample {
      Some(ns) => sorted.push(ns)
      None => return None
    }
  }
  sorted.sort()
  let rank = (percentile * sorted.length() + 99) / 100
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
  let previous = profile_samples(baseline, "baseline")
  let current = profile_samples(candidate, "candidate")
  let mut passed = true
  let reports = rules.map(rule => {
    let base_samples = previous.map(profile => rule_measurement(profile, rule))
    let next_samples = current.map(profile => rule_measurement(profile, rule))
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
      ("baseline_sample_count", Json::number(previous.length().to_double())),
      ("candidate_sample_count", Json::number(current.length().to_double())),
      ("rules", Json::array(reports)),
    ]),
  )
}
