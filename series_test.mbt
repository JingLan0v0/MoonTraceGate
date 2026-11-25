///|
fn traces(times : Array[Int32]) -> Json {
  Json::array(
    times.map(duration => {
      Json::array([
        Json::object(
          Map([
            ("ph", Json::string("X")),
            ("name", Json::string("build")),
            ("ts", Json::number(0.0)),
            ("pid", Json::number(1.0)),
            ("tid", Json::number(1.0)),
            ("dur", Json::number(duration.to_double())),
          ]),
        ),
      ])
    }),
  )
}

///|
test "series p50 accepts a spike that p95 rejects" {
  let b = traces([2, 2, 2])
  let c = traces([2, 9, 2])
  let p50 =
    #|{"rules":[{"name":"build","metric":"self_ns","max_growth_ns":1000}]}
  let p95 =
    #|{"percentile":95,"rules":[{"name":"build","metric":"self_ns","max_growth_ns":1000}]}
  guard @tracegate.check_series(b, c, @tracegate.parse_json(p50))
    is Object(median) else {
    fail("median report")
  }
  guard @tracegate.check_series(b, c, @tracegate.parse_json(p95))
    is Object(tail) else {
    fail("tail report")
  }
  assert_eq(median.get("status"), Some(Json::string("pass")))
  assert_eq(tail.get("status"), Some(Json::string("fail")))
  guard tail.get("rules") is Some(Array(reports)) && reports[0] is Object(rule) else {
    fail("tail rule")
  }
  assert_eq(
    rule.get("candidate_samples_ns"),
    Some(
      Json::array([
        Json::number(2000.0),
        Json::number(9000.0),
        Json::number(2000.0),
      ]),
    ),
  )
  assert_eq(rule.get("delta_ns"), Some(Json::number(7000.0)))
}

///|
test "a missing candidate in any sample fails the rule" {
  let base = traces([0, 1, 2])
  guard base is Array(samples) else { fail("samples") }
  let candidate = Json::array([samples[0], Json::array([]), samples[2]])
  let input =
    #|{"rules":[{"name":"build","metric":"total_ns","limit_ns":2000}]}
  guard @tracegate.check_series(base, candidate, @tracegate.parse_json(input))
    is Object(report) else {
    fail("report")
  }
  assert_eq(report.get("status"), Some(Json::string("fail")))
  guard report.get("rules") is Some(Array(results)) &&
    results[0] is Object(rule) else {
    fail("rule")
  }
  assert_eq(rule.get("candidate_ns"), Some(Json::null()))
  assert_eq(
    rule.get("reasons"),
    Some(Json::array([Json::string("missing_candidate")])),
  )
}
