// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingSettings {
  OnboardingSettings._();

  static const String _prefsKeyCompleted = 'onboarding.completed_v1';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyCompleted) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyCompleted, true);
  }

  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyCompleted);
  }
}
