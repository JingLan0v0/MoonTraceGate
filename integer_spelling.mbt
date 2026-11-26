///|
fn unit_at(units : ArrayView[UInt16], index : Int32) -> Int32 {
  if index < units.length() {
    units[index].to_int()
  } else {
    -1
  }
}

///|
fn is_digit(code : Int32) -> Bool {
  code >= 48 && code <= 57
}

///|
/// Decode a nonnegative JSON decimal within bounds. Positive scales can
/// round to the nearest unit, using the first discarded digit.
fn bounded_decimal(
  spelling : String,
  scale : Int32,
  limit : Int64,
  round_fraction~ : Bool = false,
) -> Int64? {
  if spelling.length() == 0 || spelling.length() > 200000 {
    return None
  }
  let units = spelling.code_units()
  let negative = unit_at(units, 0) == 45
  let first = if negative { 1 } else { 0 }
  let mut cursor = first
  let mut whole_digits = 0
  let mut fractional_digits = 0
  let mut after_dot = false
  let mut leading_zeros = 0
  let mut first_nonzero = -1
  let mut last_nonzero = 0
  while true {
    let code = unit_at(units, cursor)
    if is_digit(code) {
      let digit = code - 48
      if after_dot {
        fractional_digits += 1
      } else {
        whole_digits += 1
      }
      if digit != 0 {
        if first_nonzero < 0 {
          first_nonzero = cursor
        }
        last_nonzero = whole_digits + fractional_digits
      } else if first_nonzero < 0 {
        leading_zeros += 1
      }
      cursor += 1
    } else if code == 46 && !after_dot && whole_digits > 0 {
      after_dot = true
      cursor += 1
    } else {
      break
    }
  }
  if whole_digits == 0 ||
    (after_dot && fractional_digits == 0) ||
    (whole_digits > 1 && unit_at(units, first) == 48) {
    return None
  }
  let mut exponent = 0
  let marker = unit_at(units, cursor)
  if marker == 69 || marker == 101 {
    cursor += 1
    let sign = unit_at(units, cursor)
    if sign == 43 || sign == 45 {
      cursor += 1
    }
    let mut code = unit_at(units, cursor)
    if !is_digit(code) {
      return None
    }
    // An exponent beyond the spelling length cannot be cancelled by its digits.
    let cap = units.length() + 25
    while is_digit(code) {
      let next = exponent * 10 + code - 48
      exponent = if next > cap { cap } else { next }
      cursor += 1
      code = unit_at(units, cursor)
    }
    if sign == 45 {
      exponent = -exponent
    }
  }
  if cursor != units.length() {
    return None
  }
  if first_nonzero < 0 {
    return Some(0L)
  }
  if negative {
    return None
  }
  let integer_digits = whole_digits + exponent + scale - leading_zeros
  let significant_digits = last_nonzero - leading_zeros
  let has_fraction = significant_digits > integer_digits
  if integer_digits > 19 || (has_fraction && !round_fraction) {
    return None
  }
  if integer_digits < 0 {
    return Some(0L)
  }
  let mut value = 0L
  cursor = first_nonzero
  for index in 0..<integer_digits {
    let digit = if index < significant_digits {
      if unit_at(units, cursor) == 46 {
        cursor += 1
      }
      let digit = (unit_at(units, cursor) - 48).to_int64()
      cursor += 1
      digit
    } else {
      0L
    }
    if value > (limit - digit) / 10L {
      return None
    }
    value = value * 10L + digit
  }
  if has_fraction {
    if value == limit {
      return None
    }
    if unit_at(units, cursor) == 46 {
      cursor += 1
    }
    if unit_at(units, cursor) >= 53 {
      value += 1L
    }
  }
  Some(value)
}
