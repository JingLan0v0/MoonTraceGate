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

///|
test "text budgets reject decimals rounded to integers" {
  guard traces([1]) is Array(samples) else { fail("expected trace sample") }
  let p = @tracegate.profile(samples[0])
  for
    spelling in [
      "1000.00000000000000001", "-1e-999", "9007199254740990.9", "9007199254740992",
    ] {
    let prefix = "[{\"name\":\"build\",\"metric\":\"total_ns\",\"limit_ns\":"
    let rules = @tracegate.parse_json(prefix + spelling + "}]")
    try @tracegate.check_budget(p, p, rules) |> ignore catch {
      @tracegate.TraceError(code, _) => assert_eq(code, "invalid_input")
    } noraise {
      _ => fail("accepted \{spelling}")
    }
  }
}

///|
test "series accepts exact decimal integers and rejects rounded percentiles" {
  let input = traces([1, 1, 1])
  let suffix =
    #|,"rules":[{"name":"build","metric":"total_ns","limit_ns":10000e-1,"max_growth_ns":-0.000}]}
  let valid = @tracegate.parse_json("{\"percentile\":5.0e1" + suffix)
  guard @tracegate.check_series(input, input, valid) is Object(report) else {
    fail("expected report")
  }
  assert_eq(report.get("status"), Some(Json::string("pass")))
  assert_eq(report.get("percentile"), Some(Json::number(50.0)))
  let invalid = @tracegate.parse_json(
    "{\"percentile\":50.00000000000000001" + suffix,
  )
  try @tracegate.check_series(input, input, invalid) |> ignore catch {
    @tracegate.TraceError(code, _) => assert_eq(code, "invalid_input")
  } noraise {
    _ => fail("accepted fractional percentile")
  }
}

///|
test "series retains rule order and each side's sample order and count" {
  let policy =
    #|{"rules":[{"name":"missing","metric":"total_ns","limit_ns":1000},{"name":"build","metric":"self_ns","max_growth_ns":1000}]}
  let baseline = traces([3, 1, 2])
  let candidate = traces([3, 0, 1, 2])
  guard @tracegate.check_series(
      baseline,
      candidate,
      @tracegate.parse_json(policy),
    )
    is Object(report) else {
    fail("expected series report")
  }
  assert_eq(report.get("baseline_sample_count"), Some(Json::number(3.0)))
  assert_eq(report.get("candidate_sample_count"), Some(Json::number(4.0)))
  guard report.get("rules") is Some(Array(rows)) &&
    rows[0] is Object(missing) &&
    rows[1] is Object(build) else {
    fail("expected two rules in order")
  }
  assert_eq(missing.get("name"), Some(Json::string("missing")))
  assert_eq(build.get("name"), Some(Json::string("build")))
  assert_eq(
    missing.get("candidate_samples_ns"),
    Some(Json::array(Array::make(4, Json::null()))),
  )
  assert_eq(
    build.get("baseline_samples_ns"),
    Some(Json::array([3000.0, 1000.0, 2000.0].map(n => Json::number(n)))),
  )
  assert_eq(
    build.get("candidate_samples_ns"),
    Some(Json::array([3000.0, 0.0, 1000.0, 2000.0].map(n => Json::number(n)))),
  )
}

///|
test "p95 scans the maximum for 19 samples but uses an interior rank for 20" {
  let policy =
    #|{"percentile":95,"rules":[{"name":"build","metric":"max_ns","limit_ns":2000}]}
  let parsed = @tracegate.parse_json(policy)
  for
    (size, expected_status, measured) in [
      (19, "fail", 9000.0),
      (20, "pass", 2000.0),
    ] {
    let times = Array::make(size, 2)
    times[size - 1] = 9
    let baseline = traces(Array::make(size, 2))
    let candidate = traces(times)
    guard @tracegate.check_series(baseline, candidate, parsed) is Object(report) &&
      report.get("rules") is Some(Array(rows)) &&
      rows[0] is Object(row) else {
      fail("expected series report")
    }
    assert_eq(report.get("status"), Some(Json::string(expected_status)))
    assert_eq(row.get("candidate_ns"), Some(Json::number(measured)))
  }
  let full = traces(Array::make(19, 2))
  guard traces(Array::make(19, 2)) is Array(samples) else {
    fail("expected samples")
  }
  samples[18] = Json::array([])
  guard @tracegate.check_series(full, Json::array(samples), parsed)
    is Object(report) &&
    report.get("rules") is Some(Array(rows)) &&
    rows[0] is Object(row) else {
    fail("expected series report")
  }
  assert_eq(report.get("status"), Some(Json::string("fail")))
  assert_eq(row.get("candidate_ns"), Some(Json::null()))
}
