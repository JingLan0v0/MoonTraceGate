///|
let usage : String = "Usage: moon-tracegate <baseline.json> <candidate.json> <rules.json>\n" +
  "       moon-tracegate --series <baseline-series.json> <candidate-series.json> <policy.json>\n" +
  "Use - for at most one file to read standard input. Exit 0 pass, 1 budget failure, 2 invalid input.\n"

///|
fn read(path : String, label : String) -> Json raise @tracegate.TraceError {
  let result = read_utf8(path)
  if result[0] != "" {
    raise @tracegate.TraceError("io", label + ": " + result[0])
  }
  @tracegate.parse_json(result[1]) catch {
    @tracegate.TraceError(code, message) =>
      raise @tracegate.TraceError(code, label + ": " + message)
  }
}

///|
fn load_profile(
  path : String,
  label : String,
) -> @tracegate.Profile raise @tracegate.TraceError {
  let value = read(path, label)
  @tracegate.profile(value) catch {
    @tracegate.TraceError(code, message) =>
      raise @tracegate.TraceError(code, label + ": " + message)
  }
}

///|
fn main {
  initialize_output()
  let args = arguments()
  if args.length() == 1 && args[0] == "--help" {
    write_stdout(usage)
    return
  }
  if args.length() == 1 && args[0] == "--version" {
    write_stdout(@tracegate.version() + "\n")
    return
  }
  let series = args.length() == 4 && args[0] == "--series"
  if args.length() != 3 && !series {
    write_stderr(usage)
    set_exit(2)
    return
  }
  let mut stdin_count = 0
  for arg in args {
    if arg == "-" {
      stdin_count += 1
    }
  }
  if stdin_count > 1 {
    write_stderr("invalid_input: standard input can be used only once\n")
    set_exit(2)
    return
  }
  try {
    let report = if series {
      @tracegate.check_series(
        read(args[1], "baseline"),
        read(args[2], "candidate"),
        read(args[3], "series policy"),
      )
    } else {
      let a = load_profile(args[0], "baseline")
      let b = load_profile(args[1], "candidate")
      @tracegate.check_budget(a, b, read(args[2], "rules"))
    }
    write_stdout(report.stringify() + "\n")
    if report is Object(obj) && obj.get("status") == Some(Json::string("fail")) {
      set_exit(1)
    }
  } catch {
    @tracegate.TraceError(code, message) => {
      write_stderr(code + ": " + message + "\n")
      set_exit(2)
    }
  }
}
