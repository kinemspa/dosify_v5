import 'dart:math' as math;

/// Shared parsing/formatting rules for dose values.
///
/// Goal: keep unit precision/clamping consistent across dose entry surfaces.
class DoseValueFormatter {
  static double stepSizeForUnit(String unit) {
    final u = unit.trim().toLowerCase();

    if (u.isEmpty) return 1.0;

    // Volumes
    if (u == 'ml' || u.contains('ml')) return 0.01;

    // Insulin/"units" style.
    if (u == 'u' || u.contains('unit')) return 1.0;

    // Discrete counts.
    if (u.contains('tablet') ||
        u.contains('capsule') ||
        u.contains('vial') ||
        u.contains('syringe')) {
      return 1.0;
    }

    // Mass/concentration/other: allow tenths by default.
    return 0.1;
  }

  static int decimalPlacesForUnit(String unit) {
    final u = unit.trim().toLowerCase();

    if (u.isEmpty) return 0;
    if (u == 'ml' || u.contains('ml')) return 2;
    if (u == 'u' || u.contains('unit')) return 0;
    if (u.contains('tablet') ||
        u.contains('capsule') ||
        u.contains('vial') ||
        u.contains('syringe')) {
      return 0;
    }

    return 1;
  }

  static double clampToStep(double value, String unit) {
    final step = stepSizeForUnit(unit);
    if (step <= 0) return value;

    final scaled = value / step;
    final rounded = scaled.roundToDouble();
    return rounded * step;
  }

  static double clampAndQuantize(
    double value,
    String unit, {
    double min = 0.0,
    double max = double.infinity,
  }) {
    final clamped = value.clamp(min, max).toDouble();
    return clampToStep(clamped, unit).clamp(min, max).toDouble();
  }

  static double? tryParseAndClamp(
    String raw,
    String unit, {
    double min = 0.0,
    double max = double.infinity,
  }) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null) return null;
    return clampAndQuantize(parsed, unit, min: min, max: max);
  }

  static String format(double value, String unit) {
    final decimals = decimalPlacesForUnit(unit);

    if (decimals <= 0) {
      return value.round().toString();
    }

    final fixed = value.toStringAsFixed(decimals);
    return _trimFixed(fixed);
  }

  static String _trimFixed(String value) {
    if (!value.contains('.')) return value;
    return value.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  static double safeAdd(double a, double b) {
    if (a.isNaN || b.isNaN) return 0;
    if (a.isInfinite || b.isInfinite) return 0;
    return a + b;
  }

  static double safeSubtract(double a, double b) {
    if (a.isNaN || b.isNaN) return 0;
    if (a.isInfinite || b.isInfinite) return 0;
    return a - b;
  }

  static double safeClampMax(double value, double max) {
    if (max.isInfinite) return value;
    return math.min(value, max);
  }
}
