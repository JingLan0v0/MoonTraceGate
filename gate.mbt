///|
priv enum Metric {
  Total
  Self
  Peak
}

///|
priv struct Rule {
  cat : String
  name : String
  metric : String
  value : Metric
  limit_ns : Int64?
  max_growth_ns : Int64?
}

///|
fn read_limit(
  obj : Map[String, Json],
  field : String,
) -> Int64? raise TraceError {
  match obj.get(field) {
    None => None
    Some(n) => Some(integer(n, field, 9007199254740991.0))
  }
}

///|
fn read_rule(input : Json) -> Rule raise TraceError {
  guard input is Object(obj) else {
    raise TraceError("invalid_input", "each budget rule must be an object")
  }
  for key in obj.keys() {
    if !["cat", "name", "metric", "limit_ns", "max_growth_ns"].contains(key) {
      raise TraceError("invalid_input", "unknown budget rule field: " + key)
    }
  }
  let cat = match obj.get("cat") {
    None => ""
    Some(v) => read_text(v, "cat")
  }
  let name = read_text(required(obj, "name"), "name")
  if name == "" {
    raise TraceError("invalid_input", "budget rule name must be nonempty")
  }
  let metric = read_text(required(obj, "metric"), "metric")
  let value = match metric {
    "total_ns" => Total
    "self_ns" => Self
    "max_ns" => Peak
    _ =>
      raise TraceError(
        "invalid_input", "metric must be total_ns, self_ns or max_ns",
      )
  }
  let limit_ns = read_limit(obj, "limit_ns")
  let max_growth_ns = read_limit(obj, "max_growth_ns")
  if limit_ns is None && max_growth_ns is None {
    raise TraceError("invalid_input", "at least one limit is required")
  }
  { cat, name, metric, value, limit_ns, max_growth_ns, }
}

///|
fn measure(stats : SpanStats, metric : Metric) -> Int64 {
  match metric {
    Total => stats.total_ns
    Self => stats.self_ns
    Peak => stats.max_ns
  }
}

///|
fn number(n : Int64?) -> Json {
  match n {
    Some(value) => Json::number(value.to_double())
    None => Json::null()
  }
}

///|
fn read_rules(rules : Json) -> Array[Rule] raise TraceError {
  guard rules is Array(values) && values.length() > 0 && values.length() <= 64 else {
    raise TraceError("invalid_input", "expected an array of 1..64 budget rules")
  }
  let seen : Map[(String, String, String), Bool] = Map([])
  values.map(value => {
    let rule = read_rule(value)
    let key = (rule.cat, rule.name, rule.metric)
    if seen.contains(key) {
      raise TraceError("invalid_input", "duplicate budget rule")
    }
    seen[key] = true
    rule
  })
}

///|
fn rule_measurement(profile : Profile, rule : Rule) -> Int64? {
  profile.lookup(rule.cat, rule.name).map(s => measure(s, rule.value))
}

///|
fn budget_result(
  rule : Rule,
  base : Int64?,
  current : Int64?,
) -> (Map[String, Json], Bool) {
  let delta = match (base, current) {
    (Some(a), Some(b)) => Some(b - a)
    _ => None
  }
  let reasons : Array[Json] = []
  if current is None {
    reasons.push(Json::string("missing_candidate"))
  }
  if rule.max_growth_ns is Some(limit) {
    if base is None {
      reasons.push(Json::string("missing_baseline"))
    }
    if delta is Some(growth) && growth > limit {
      reasons.push(Json::string("growth_limit"))
    }
  }
  if rule.limit_ns is Some(limit) &&
    current is Some(measured) &&
    measured > limit {
    reasons.push(Json::string("absolute_limit"))
  }
  let values = Map([
    ("cat", Json::string(rule.cat)),
    ("name", Json::string(rule.name)),
    ("metric", Json::string(rule.metric)),
    ("baseline_ns", number(base)),
    ("candidate_ns", number(current)),
    ("delta_ns", number(delta)),
    ("limit_ns", number(rule.limit_ns)),
    ("max_growth_ns", number(rule.max_growth_ns)),
    ("reasons", Json::array(reasons)),
  ])
  (values, reasons.is_empty())
}

///|
/// Compare profiles with 1..64 JSON rules. Missing measurements fail the affected
/// rule. An absolute-only rule may target an event that is new in the candidate.
pub fn check_budget(
  baseline : Profile,
  candidate : Profile,
  rules : Json,
) -> Json raise TraceError {
  let mut passed = true
  let reports = read_rules(rules).map(rule => {
    let base = rule_measurement(baseline, rule)
    let current = rule_measurement(candidate, rule)
    let (record, ok) = budget_result(rule, base, current)
    passed = passed && ok
    Json::object(record)
  })
  Json::object(
    Map([
      ("status", Json::string(if passed { "pass" } else { "fail" })),
      ("baseline_spans", Json::number(baseline.spans.to_double())),
      ("candidate_spans", Json::number(candidate.spans.to_double())),
      ("baseline_skipped", Json::number(baseline.skipped.to_double())),
      ("candidate_skipped", Json::number(candidate.skipped.to_double())),
      ("rules", Json::array(reports)),
    ]),
  )
}

///|
pub fn version() -> String {
  "0.2.1"
}
