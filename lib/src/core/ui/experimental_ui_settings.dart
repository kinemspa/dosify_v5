import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ExperimentalUiConfig {
  const ExperimentalUiConfig({required this.showMedicationListStatusBadges});

  final bool showMedicationListStatusBadges;

  ExperimentalUiConfig copyWith({bool? showMedicationListStatusBadges}) {
    return ExperimentalUiConfig(
      showMedicationListStatusBadges:
          showMedicationListStatusBadges ?? this.showMedicationListStatusBadges,
    );
  }
}

class ExperimentalUiSettings {
  const ExperimentalUiSettings._();

  static const String _prefsKeyShowMedicationListStatusBadges =
      'experimental_ui.show_medication_list_status_badges_v1';

  static const bool defaultShowMedicationListStatusBadges = true;

  static final ValueNotifier<ExperimentalUiConfig> value = ValueNotifier(
    const ExperimentalUiConfig(
      showMedicationListStatusBadges: defaultShowMedicationListStatusBadges,
    ),
  );

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final showBadges =
          prefs.getBool(_prefsKeyShowMedicationListStatusBadges) ??
          defaultShowMedicationListStatusBadges;

      value.value = value.value.copyWith(
        showMedicationListStatusBadges: showBadges,
      );
    } catch (_) {
      // Best-effort; keep defaults.
    }
  }

  static Future<void> setShowMedicationListStatusBadges(bool enabled) async {
    value.value = value.value.copyWith(showMedicationListStatusBadges: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyShowMedicationListStatusBadges, enabled);
    } catch (_) {
      // Best-effort.
    }
  }
}
