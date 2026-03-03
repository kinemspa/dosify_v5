// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingSettings {
  OnboardingSettings._();

  static const String _prefix = 'onboarding.seen.';

  // Legacy key kept for migration (treat legacy "all done" as every screen seen).
  static const String _legacyCompletedKey = 'onboarding.completed_v1';

  static final ValueNotifier<int> replaySignal = ValueNotifier<int>(0);

  /// All route IDs that have onboarding tips.
  static const List<String> allTipRouteIds = [
    '/',
    '/medications',
    '/medications/:id',
    '/medications/reconstitution',
    '/schedules',
    '/schedules/detail/:id',
    '/calendar',
    '/analytics',
    '/inventory',
    '/settings',
  ];

  /// Returns true if this screen's tip has already been dismissed.
  static Future<bool> isScreenSeen(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    // If the user dismissed everything via the legacy wizard, count all as seen.
    if (prefs.getBool(_legacyCompletedKey) ?? false) return true;
    return prefs.getBool('$_prefix$routeId') ?? false;
  }

  /// Marks a single screen's tip as dismissed.
  static Future<void> markScreenSeen(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$routeId', true);
  }

  /// Marks every screen's tip as dismissed ("Skip all").
  static Future<void> markAllSeen() async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in allTipRouteIds) {
      await prefs.setBool('$_prefix$id', true);
    }
    await prefs.setBool(_legacyCompletedKey, true);
  }

  /// Resets all tips so they show again (used by Settings → Replay tour).
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyCompletedKey);
    for (final id in allTipRouteIds) {
      await prefs.remove('$_prefix$id');
    }
    replaySignal.value = replaySignal.value + 1;
  }

  // ── Legacy API surface (kept so Settings page still compiles) ──────────────

  static Future<bool> isCompleted() => isScreenSeen('/');

  static Future<void> markCompleted() => markAllSeen();

  static Future<void> resetForTesting() => resetAll();

  static Future<void> replay() => resetAll();
}
