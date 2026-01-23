import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ExperimentalUiConfig {
  const ExperimentalUiConfig({
    required this.showMedicationListStatusBadges,
    required this.showWideCardSamplesEntry,
  });

  final bool showMedicationListStatusBadges;
  final bool showWideCardSamplesEntry;

  ExperimentalUiConfig copyWith({
    bool? showMedicationListStatusBadges,
    bool? showWideCardSamplesEntry,
  }) {
    return ExperimentalUiConfig(
      showMedicationListStatusBadges:
          showMedicationListStatusBadges ?? this.showMedicationListStatusBadges,
      showWideCardSamplesEntry:
          showWideCardSamplesEntry ?? this.showWideCardSamplesEntry,
    );
  }
}

class ExperimentalUiSettings {
  const ExperimentalUiSettings._();

  static const String _prefsKeyShowMedicationListStatusBadges =
      'experimental_ui.show_medication_list_status_badges_v1';
  static const String _prefsKeyShowWideCardSamplesEntry =
      'experimental_ui.show_wide_card_samples_entry_v1';

  static const bool defaultShowMedicationListStatusBadges = true;
  static const bool defaultShowWideCardSamplesEntry = true;

  static final ValueNotifier<ExperimentalUiConfig> value = ValueNotifier(
    const ExperimentalUiConfig(
      showMedicationListStatusBadges: defaultShowMedicationListStatusBadges,
      showWideCardSamplesEntry: defaultShowWideCardSamplesEntry,
    ),
  );

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final showBadges =
          prefs.getBool(_prefsKeyShowMedicationListStatusBadges) ??
          defaultShowMedicationListStatusBadges;
      final showWideCardSamples =
          prefs.getBool(_prefsKeyShowWideCardSamplesEntry) ??
          defaultShowWideCardSamplesEntry;

      value.value = value.value.copyWith(
        showMedicationListStatusBadges: showBadges,
        showWideCardSamplesEntry: showWideCardSamples,
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

  static Future<void> setShowWideCardSamplesEntry(bool enabled) async {
    value.value = value.value.copyWith(showWideCardSamplesEntry: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyShowWideCardSamplesEntry, enabled);
    } catch (_) {
      // Best-effort.
    }
  }
}
