import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class SnoozeConfig {
  const SnoozeConfig({required this.defaultSnoozePercent});

  /// Percentage (0..100) of the available window until the next scheduled dose
  /// (minus a small safety buffer) that should be used as the default snooze.
  final int defaultSnoozePercent;

  SnoozeConfig copyWith({int? defaultSnoozePercent}) {
    return SnoozeConfig(
      defaultSnoozePercent: defaultSnoozePercent ?? this.defaultSnoozePercent,
    );
  }
}

class SnoozeSettings {
  const SnoozeSettings._();

  static const String _prefsKeyDefaultSnoozePercent =
      'dose_snooze.default_percent_v1';

  static const int defaultDefaultSnoozePercent = 65;

  static final ValueNotifier<SnoozeConfig> value = ValueNotifier(
    const SnoozeConfig(defaultSnoozePercent: defaultDefaultSnoozePercent),
  );

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pct =
          prefs.getInt(_prefsKeyDefaultSnoozePercent) ??
          defaultDefaultSnoozePercent;
      value.value = value.value.copyWith(defaultSnoozePercent: _clamp(pct));
    } catch (_) {
      // Best-effort.
    }
  }

  static int _clamp(int raw) => raw.clamp(0, 100);

  static Future<void> setDefaultSnoozePercent(int percent) async {
    final next = _clamp(percent);
    value.value = value.value.copyWith(defaultSnoozePercent: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyDefaultSnoozePercent, next);
    } catch (_) {
      // Best-effort.
    }
  }
}
