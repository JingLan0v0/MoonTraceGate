///|
pub(all) suberror TraceError {
  TraceError(String, String)
}

///|
fn required(obj : Map[String, Json], key : String) -> Json raise TraceError {
  match obj.get(key) {
    Some(value) => value
    None => raise TraceError("invalid_input", "missing field: " + key)
  }
}

///|
fn read_text(value : Json, field : String) -> String raise TraceError {
  guard value is String(text) && text.length() <= 128 else {
    raise TraceError(
      "invalid_input",
      field + " must be a string of at most 128 UTF-16 units",
    )
  }
  text
}

///|
fn integer(
  value : Json,
  field : String,
  limit : Double,
) -> Int64 raise TraceError {
  guard value is Number(n, repr~) && n >= 0.0 && n <= limit && n.floor() == n else {
    raise TraceError(
      "invalid_input",
      field + " must be a bounded nonnegative integer",
    )
  }
  let decoded = n.to_int64()
  if repr is Some(spelling) &&
    bounded_decimal(spelling, 0, limit.to_int64()) != Some(decoded) {
    raise TraceError(
      "invalid_input",
      field + " must be a bounded nonnegative integer",
    )
  }
  decoded
}

///|
fn picoseconds(
  value : Json,
  field : String,
  limit : Int64,
) -> Int64 raise TraceError {
  let message = field + " must be bounded nonnegative microseconds"
  guard value is Number(n, repr~) && n >= 0.0 && n <= limit.to_double() else {
    raise TraceError("invalid_trace", message)
  }
  if repr is Some(spelling) {
    guard bounded_decimal(spelling, 6, limit * 1000000L, round_fraction=true)
      is Some(picos) else {
      raise TraceError("invalid_trace", message)
    }
    return picos
  }
  // Programmatic JSON numbers without spelling have only the decoded value.
  let whole = n.floor()
  whole.to_int64() * 1000000L + ((n - whole) * 1000000.0).round().to_int64()
}

///|
fn endpoint_ns(ps : Int64) -> Int64 {
  (ps + 500L) / 1000L
}

///|
/// Preflight bounds decoder work before delegating exact JSON grammar to core.
pub fn parse_json(source : String) -> Json raise TraceError {
  if source.length() > 1048576 {
    raise TraceError("limit_exceeded", "JSON exceeds 1 Mi UTF-16 units")
  }
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  let mut tokens = 0
  let mut string_units = 0
  for c in source.iter() {
    if quoted {
      string_units += 1
      if string_units > 256 {
        raise TraceError(
          "limit_exceeded", "JSON string exceeds 256 source characters",
        )
      }
      if escaped {
        escaped = false
      } else if c == '\\' {
        escaped = true
      } else if c == '"' {
        quoted = false
      }
    } else {
      if c == '"' {
        quoted = true
        string_units = 0
      }
      if c == '{' || c == '[' {
        depth += 1
      }
      if c == '}' || c == ']' {
        depth -= 1
      }
      if c != ' ' && c != '\n' && c != '\r' && c != '\t' {
        tokens += 1
      }
      if depth > 16 || tokens > 200000 {
        raise TraceError(
          "limit_exceeded", "JSON nesting or token budget exceeded",
        )
      }
    }
  }
  @json.parse(
    source,
    max_nesting_depth=16,
    reject_duplicate_keys=true,
    preserve_number_repr=true,
  ) catch {
    _ => raise TraceError("invalid_json", "invalid JSON text")
  }
}
