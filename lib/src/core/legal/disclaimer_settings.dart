// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has accepted the Dosifi disclaimer.
///
/// Acceptance is recorded once and survives app restarts. Clearing app data
/// or reinstalling will prompt the dialog again.
class DisclaimerSettings {
  DisclaimerSettings._();

  static const String _prefsKey = 'disclaimer.accepted_v1';

  /// Returns true if the user has already accepted the disclaimer.
  static Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Marks the disclaimer as accepted.
  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// Clears acceptance (for testing / replay from Settings).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
