///|
test "nested B E and X: direct child time is subtracted exactly once" {
  let trace = @tracegate.parse_json(
    (
      #|[{"ph":"B","pid":1,"tid":1,"cat":"build","name":"outer","ts":0.125},{"ph":"X","pid":1,"tid":1,"cat":"build","name":"child","ts":1,"dur":3.25},{"ph":"X","pid":1,"tid":1,"name":"grandchild","ts":2,"dur":1},{"ph":"E","pid":1,"tid":1,"ts":8.125}]
    ),
  )
  let p = @tracegate.profile(trace)
  guard p.lookup("build", "outer") is Some(outer) else { fail("missing outer") }
  guard p.lookup("build", "child") is Some(child) else { fail("missing child") }
  assert_eq(outer.total_ns, 8000L)
  assert_eq(outer.self_ns, 4750L)
  assert_eq(child.self_ns, 2250L)
}

///|
test "separate tracks and touching spans do not steal own time" {
  let trace = @tracegate.parse_json(
    (
      #|[{"ph":"X","pid":1,"tid":1,"name":"parse","ts":1,"dur":3},{"ph":"X","pid":1,"tid":2,"name":"parse","ts":2,"dur":4},{"ph":"X","pid":1,"tid":1,"name":"parse","ts":4,"dur":1}]
    ),
  )
  guard @tracegate.profile(trace).lookup("", "parse") is Some(s) else {
    fail("missing parse")
  }
  assert_eq(s.count, 3)
  assert_eq(s.self_ns, 8000L)
  assert_eq(s.max_ns, 4000L)
}

///|
test "crossed completed events produce an error" {
  let bad = @tracegate.parse_json(
    (
      #|[{"ph":"X","pid":1,"tid":1,"name":"a","ts":0,"dur":3},{"ph":"X","pid":1,"tid":1,"name":"b","ts":2,"dur":3}]
    ),
  )
  try @tracegate.profile(bad) |> ignore catch {
    @tracegate.TraceError(code, _) => assert_eq(code, "invalid_trace")
  } noraise {
    _ => fail("crossing spans accepted")
  }
}

///|
test "B/E and X representations of the same fractional interval agree" {
  let complete = @tracegate.parse_json(
    "[{\"ph\":\"X\",\"pid\":1,\"tid\":1,\"name\":\"build\",\"ts\":0.0006,\"dur\":0.0016}]",
  )
  let paired = @tracegate.parse_json(
    "[{\"ph\":\"B\",\"pid\":1,\"tid\":1,\"name\":\"build\",\"ts\":0.0006},{\"ph\":\"E\",\"pid\":1,\"tid\":1,\"ts\":0.0022}]",
  )
  guard @tracegate.profile(complete).lookup("", "build") is Some(x) else {
    fail("missing X")
  }
  guard @tracegate.profile(paired).lookup("", "build") is Some(be) else {
    fail("missing pair")
  }
  assert_eq(x.total_ns, be.total_ns)
  assert_eq(x.total_ns, 1L)
}

///|
test "earlier end cannot be hidden in the same nanosecond as begin" {
  let trace = @tracegate.parse_json(
    "[{\"ph\":\"B\",\"pid\":1,\"tid\":1,\"name\":\"early\",\"ts\":0.0004},{\"ph\":\"E\",\"pid\":1,\"tid\":1,\"ts\":0.0003}]",
  )
  try @tracegate.profile(trace) |> ignore catch {
    @tracegate.TraceError(code, _) => assert_eq(code, "invalid_trace")
  } noraise {
    _ => fail("earlier end accepted")
  }
}

///|
test "crossing spans are rejected before endpoint rounding" {
  let trace = @tracegate.parse_json(
    "[{\"ph\":\"X\",\"pid\":1,\"tid\":1,\"name\":\"a\",\"ts\":0,\"dur\":0.0004},{\"ph\":\"X\",\"pid\":1,\"tid\":1,\"name\":\"b\",\"ts\":0.0002,\"dur\":0.0004}]",
  )
  try @tracegate.profile(trace) |> ignore catch {
    @tracegate.TraceError(code, _) => assert_eq(code, "invalid_trace")
  } noraise {
    _ => fail("crossing spans accepted")
  }
}
