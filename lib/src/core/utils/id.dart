import 'dart:math';

/// Generates unique, time-sortable string IDs.
///
/// Format: `<prefix_?> <microsecondsSinceEpoch>_<randomHex>`
/// Example: `med_1738277123456789_1a2b3c4d`
class IdGen {
  static final Random _rng = Random.secure();

  static String newId({String prefix = ''}) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final rand = _rng.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');

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
