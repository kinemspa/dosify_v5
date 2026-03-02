import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Visual layout style for [DoseCard] widgets throughout the app.
enum DoseCardLayout {
  /// Narrow time pill on the left, med name + schedule in center, status chip
  /// right. The original compact pill — time only, no content duplication.
  pill,

  /// Left coloured accent strip (status colour), time shown inline on the
  /// first row alongside med name and status chip. No pill block.
  accent,

  /// Ultra-compact: a small status dot + time inline, med name expanded,
  /// schedule + dose on a second row. No separate pill or chip block.
  minimal,
}

/// Human-readable label and description for each [DoseCardLayout].
extension DoseCardLayoutMeta on DoseCardLayout {
  String get label => switch (this) {
    DoseCardLayout.pill => 'Compact Pill',
    DoseCardLayout.accent => 'Accent Strip',
    DoseCardLayout.minimal => 'Minimal',
  };

  String get description => switch (this) {
    DoseCardLayout.pill =>
      'Time in a narrow pill on the left. Clean two-column layout.',
    DoseCardLayout.accent =>
      'Status colour bar on the left, time shown inline. No pill.',
    DoseCardLayout.minimal =>
      'Ultra-compact dot + typography only. Most space-efficient.',
  };
}

@immutable
class DoseCardLayoutConfig {
  const DoseCardLayoutConfig({required this.layout});

  final DoseCardLayout layout;

  DoseCardLayoutConfig copyWith({DoseCardLayout? layout}) =>
      DoseCardLayoutConfig(layout: layout ?? this.layout);
}

class DoseCardLayoutSettings {
  DoseCardLayoutSettings._();

  static const String _prefsKey = 'dose_card.layout_v1';
  static const DoseCardLayout _default = DoseCardLayout.accent;

  static final ValueNotifier<DoseCardLayoutConfig> value = ValueNotifier(
    const DoseCardLayoutConfig(layout: _default),
  );

  static DoseCardLayout get currentLayout => value.value.layout;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_prefsKey);
      final layout =
          (index != null && index < DoseCardLayout.values.length)
              ? DoseCardLayout.values[index]
              : _default;
      value.value = DoseCardLayoutConfig(layout: layout);
    } catch (_) {
      // Best-effort; keep defaults.
    }
  }

  static Future<void> setLayout(DoseCardLayout layout) async {
    value.value = DoseCardLayoutConfig(layout: layout);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, layout.index);
    } catch (_) {
      // Best-effort.
    }
  }
}
