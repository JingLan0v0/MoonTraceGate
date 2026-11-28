///|
priv struct Span {
  pid : Int64
  tid : Int64
  cat : String
  name : String
  start : Int64
  stop : Int64
  index : Int32
}

///|
priv struct PairingEvent {
  span : Span
  opens_span : Bool
}

///|
priv enum Event {
  Complete(Span)
  Pairing(PairingEvent)
}

///|
pub(all) struct SpanStats {
  count : Int32
  total_ns : Int64
  self_ns : Int64
  max_ns : Int64
}

///|
pub struct Profile {
  totals : Map[(String, String), SpanStats]
  spans : Int32
  skipped : Int32
}

///|
pub fn Profile::lookup(
  self : Profile,
  cat : String,
  name : String,
) -> SpanStats? {
  self.totals.get((cat, name))
}

///|
fn same_lane(a : Span, b : Span) -> Bool {
  a.pid == b.pid && a.tid == b.tid
}

///|
fn by_lane_and_start(a : Span, b : Span) -> Int32 {
  if a.pid != b.pid {
    return a.pid.compare(b.pid)
  }
  if a.tid != b.tid {
    return a.tid.compare(b.tid)
  }
  a.start.compare(b.start)
}

///|
fn trace_error(s : Span, reason : String) -> TraceError {
  TraceError("invalid_trace", "event " + s.index.to_string() + ": " + reason)
}

///|
fn parse_event(value : Json, index : Int32) -> Event? raise TraceError {
  guard value is Object(obj) else {
    raise TraceError("invalid_trace", "event must be an object")
  }
  let ph = read_text(required(obj, "ph"), "ph")
  let duration = match ph {
    "B" | "E" => None
    "X" => Some(picoseconds(required(obj, "dur"), "dur", 1000000000L))
    _ => return None
  }
  let cat = match obj.get("cat") {
    None => ""
    Some(v) => read_text(v, "cat")
  }
  let name = match obj.get("name") {
    None if ph == "E" => ""
    v => read_text(v.unwrap_or(Json::null()), "name")
  }
  if ph != "E" && name == "" {
    raise TraceError("invalid_trace", "duration event name must be nonempty")
  }
  let span = {
    pid: integer(required(obj, "pid"), "pid", 2147483647.0),
    tid: integer(required(obj, "tid"), "tid", 2147483647.0),
    cat,
    name,
    start: picoseconds(required(obj, "ts"), "ts", 1000000000000L),
    stop: 0L,
    index,
  }
  match duration {
    Some(duration_ps) =>
      Some(Complete({ ..span, stop: span.start + duration_ps, }))
    None => Some(Pairing({ span, opens_span: ph == "B", }))
  }
}

///|
fn pair_spans(
  events : Array[PairingEvent],
  spans : Array[Span],
) -> Unit raise TraceError {
  if events.is_empty() {
    return
  }
  events.sort_by((a, b) => {
    let order = by_lane_and_start(a.span, b.span)
    if order == 0 {
      a.span.index.compare(b.span.index)
    } else {
      order
    }
  })
  let open : Array[Span] = []
  for event in events {
    let s = event.span
    if open.last() is Some(previous) && !same_lane(s, previous) {
      raise trace_error(previous, "unclosed begin")
    }
    if event.opens_span {
      open.push(s)
      continue
    }
    guard open.pop() is Some(begin) else {
      raise trace_error(s, "end has no matching begin on this thread")
    }
    if (s.name != "" && s.name != begin.name) ||
      (s.cat != "" && s.cat != begin.cat) {
      raise trace_error(s, "end label differs from its open span")
    }
    if s.start - begin.start > 1000000000000000L {
      raise trace_error(begin, "span duration exceeds 1000000000 microseconds")
    }
    spans.push({ ..begin, stop: s.start, })
  }
  if open.last() is Some(s) {
    raise trace_error(s, "unclosed begin")
  }
}

///|
priv struct Frame {
  span : Span
  duration_ns : Int64
  mut children_ns : Int64
}

///|
fn span_ns(span : Span) -> Int64 {
  endpoint_ns(span.stop) - endpoint_ns(span.start)
}

///|
fn finish_span(
  totals : Map[(String, String), SpanStats],
  frame : Frame,
) -> Unit {
  let span = frame.span
  let dur = frame.duration_ns
  let key = (span.cat, span.name)
  let prior = totals
    .get(key)
    .unwrap_or({ count: 0, total_ns: 0L, self_ns: 0L, max_ns: 0L, })
  totals[key] = {
    count: prior.count + 1,
    total_ns: prior.total_ns + dur,
    self_ns: prior.self_ns + dur - frame.children_ns,
    max_ns: if dur > prior.max_ns {
      dur
    } else {
      prior.max_ns
    },
  }
}

///|
fn attribute(
  spans : Array[Span],
) -> Map[(String, String), SpanStats] raise TraceError {
  spans.sort_by((a, b) => {
    let order = by_lane_and_start(a, b)
    if order != 0 {
      return order
    }
    if a.stop != b.stop {
      return b.stop.compare(a.stop)
    }
    a.index.compare(b.index)
  })
  let stack : Array[Frame] = []
  let totals : Map[(String, String), SpanStats] = Map([])
  for span in spans {
    if span.stop == span.start {
      finish_span(totals, { span, duration_ns: 0L, children_ns: 0L, })
      continue
    }
    while stack.last() is Some(parent) &&
          (!same_lane(span, parent.span) || span.start >= parent.span.stop) {
      stack.pop() |> ignore
      finish_span(totals, parent)
    }
    let duration_ns = span_ns(span)
    if stack.last() is Some(parent) {
      if span.stop > parent.span.stop {
        raise trace_error(span, "crossing duration spans on the same thread")
      }
      parent.children_ns += duration_ns
    }
    stack.push({ span, duration_ns, children_ns: 0L, })
  }
  for frame in stack {
    finish_span(totals, frame)
  }
  totals
}

///|
/// Analyze synchronous Chrome JSON duration events. Each input is capped at 4096 events.
pub fn profile(trace : Json) -> Profile raise TraceError {
  let value = match trace {
    Object(obj) => required(obj, "traceEvents")
    _ => trace
  }
  guard value is Array(values) else {
    raise TraceError(
      "invalid_trace", "expected traceEvents array or event array",
    )
  }
  if values.length() > 4096 {
    raise TraceError("limit_exceeded", "trace has more than 4096 events")
  }
  let events : Array[PairingEvent] = []
  let spans : Array[Span] = []
  let mut skipped = 0
  for index, value in values {
    match parse_event(value, index) {
      Some(Complete(span)) => spans.push(span)
      Some(Pairing(event)) => events.push(event)
      None => skipped += 1
    }
  }
  pair_spans(events, spans)
  { totals: attribute(spans), spans: spans.length(), skipped, }
}
