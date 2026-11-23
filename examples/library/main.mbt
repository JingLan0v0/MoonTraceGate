///|
fn main raise {
  let trace = @tracegate.parse_json(
    (
      #|[{"ph":"X","pid":1,"tid":1,"cat":"build","name":"compile","ts":0,"dur":7.5}]
    ),
  )
  let p = @tracegate.profile(trace)
  guard p.lookup("build", "compile") is Some(stats) else {
    abort("missing compile")
  }
  assert_eq(stats.self_ns, 7500L)
  let rules = @tracegate.parse_json(
    (
      #|[{"cat":"build","name":"compile","metric":"self_ns","limit_ns":7500}]
    ),
  )
  guard @tracegate.check_budget(p, p, rules) is Object(obj) else {
    abort("missing report")
  }
  assert_eq(obj.get("status"), Some(Json::string("pass")))
  println("PASS public API: compile self time 7500 ns")
}
