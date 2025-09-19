String fmt2(num value) {
  // Format with up to 2 decimals. Remove only fractional trailing zeros, never integers.
  String s = value.toStringAsFixed(2);
  if (s.contains('.')) {
    // Remove trailing zeros in the fractional part
    s = s.replaceAll(RegExp(r'0+$'), '');
    // If all fractional digits were removed, drop the decimal point
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

