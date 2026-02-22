String fmt2(num value) {
  // Format with up to 2 decimals. Remove only fractional trailing zeros, never integers.
  var s = value.toStringAsFixed(2);
  if (s.contains('.')) {
    // Remove trailing zeros in the fractional part
    s = s.replaceAll(RegExp(r'0+$'), '');
    // If all fractional digits were removed, drop the decimal point
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

String fmt3(num value) {
  // Format with up to 3 decimals. Remove only fractional trailing zeros, never integers.
  var s = value.toStringAsFixed(3);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

/// Formats [v] as an integer string when it is a whole number (e.g. 2.0 → "2"),
/// or with [decimals] fixed decimal places otherwise (e.g. 0.5 → "0.50").
///
/// Drop-in replacement for the inline `v == v.roundToDouble() ? ... : ...` pattern
/// scattered across the codebase. Use this instead of duplicating the check.
String fmtInt(double v, {int decimals = 2}) =>
    (v - v.roundToDouble()).abs() < 1e-9
        ? v.toInt().toString()
        : v.toStringAsFixed(decimals);
