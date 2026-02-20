import 'dart:math';

/// Generates unique, time-sortable string IDs.
///
/// Format: `<prefix_?> <microsecondsSinceEpoch>_<randomHex>`
/// Example: `med_1738277123456789_1a2b3c4d`
class IdGen {
  static Random? _rng;
  static const int _webSafeRandMax = 0x3fffffff;

  static Random _resolveRng() {
    final existing = _rng;
    if (existing != null) return existing;

    try {
      final secure = Random.secure();
      _rng = secure;
      return secure;
    } catch (_) {
      final fallback = Random();
      _rng = fallback;
      return fallback;
    }
  }

  static String newId({String prefix = ''}) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final rand =
        _resolveRng().nextInt(_webSafeRandMax).toRadixString(16).padLeft(8, '0');

    final trimmedPrefix = prefix.trim();
    if (trimmedPrefix.isEmpty) {
      return '${micros}_$rand';
    }

    final normalizedPrefix = trimmedPrefix.endsWith('_')
        ? trimmedPrefix.substring(0, trimmedPrefix.length - 1)
        : trimmedPrefix;

    return '${normalizedPrefix}_${micros}_$rand';
  }
}
