import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores user preferences for how notification action buttons behave.
class NotificationActionSettings {
  const NotificationActionSettings._();

  static const String _keyQuickLog = 'notification_action.quick_log_v1';

  /// Default: true — tapping "Log" on a notification writes the entry
  /// immediately without opening the action sheet.
  static const bool defaultQuickLog = true;

  static final ValueNotifier<bool> quickLogEnabled =
      ValueNotifier(defaultQuickLog);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      quickLogEnabled.value = prefs.getBool(_keyQuickLog) ?? defaultQuickLog;
    } catch (_) {
      // Best-effort.
    }
  }

  static Future<void> setQuickLogEnabled(bool value) async {
    quickLogEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyQuickLog, value);
    } catch (_) {
      // Best-effort.
    }
  }
}
