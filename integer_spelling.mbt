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
/// Validate an exact decimal coefficient and exponent against the accepted
/// integer range, without converting the text through floating point.
fn exact_nonnegative_integer(spelling : String) -> Int64? {
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
  let max_safe_integer = 9007199254740991L
  let mut coefficient = 0L
  let mut trailing_zeros = 0
  while true {
    let code = unit_at(units, cursor)
    if is_digit(code) {
      let digit = code - 48
      if after_dot {
        fractional_digits += 1
      } else {
        whole_digits += 1
      }
      if digit == 0 {
        if coefficient != 0L {
          trailing_zeros += 1
        }
      } else {
        if negative || trailing_zeros > 15 {
          return None
        }
        for _ in 0..<trailing_zeros {
          coefficient *= 10L
          if coefficient > max_safe_integer {
            return None
          }
        }
        coefficient = coefficient * 10L + digit.to_int64()
        if coefficient > max_safe_integer {
          return None
        }
        trailing_zeros = 0
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
    let cap = units.length() + 16
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
  if coefficient == 0L {
    return Some(0L)
  }
  let shift = trailing_zeros - fractional_digits + exponent
  if shift < 0 || shift > 15 {
    return None
  }
  for _ in 0..<shift {
    coefficient *= 10L
    if coefficient > max_safe_integer {
      return None
    }
  }
  Some(coefficient)
}
