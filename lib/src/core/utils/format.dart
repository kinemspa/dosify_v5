String fmt2(num value) {
  // Format with up to 2 decimals, trim trailing zeros and decimal point
  final s = value.toStringAsFixed(2);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.0+$'), '').replaceFirst(RegExp(r'0+$'), '') : s;
}

