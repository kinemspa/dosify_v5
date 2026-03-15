// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has accepted the Skedux disclaimer.
///
/// Acceptance is recorded once and survives app restarts. Clearing app data
/// or reinstalling will prompt the dialog again.
class DisclaimerSettings {
  DisclaimerSettings._();

  static const int currentVersion = 2;

  static const String _prefsKey = 'disclaimer.accepted_version';
  static const String _legacyPrefsKey = 'disclaimer.accepted_v1';

  /// Returns true if the user has already accepted the disclaimer.
  static Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final acceptedVersion = prefs.getInt(_prefsKey) ?? 0;
    return acceptedVersion >= currentVersion;
  }

  /// Marks the disclaimer as accepted.
  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, currentVersion);
    await prefs.remove(_legacyPrefsKey);
  }

  /// Clears acceptance (for testing / replay from Settings).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_legacyPrefsKey);
  }
}
