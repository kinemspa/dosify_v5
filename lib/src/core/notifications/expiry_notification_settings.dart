import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ExpiryNotificationConfig {
  const ExpiryNotificationConfig({required this.leadTimeDays});

  /// Number of days before expiry to trigger notification (e.g., 7, 14, 30)
  final int leadTimeDays;

  ExpiryNotificationConfig copyWith({int? leadTimeDays}) {
    return ExpiryNotificationConfig(
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
    );
  }
}

class ExpiryNotificationSettings {
  const ExpiryNotificationSettings._();

  static const String _prefsKeyLeadTimeDays =
      'expiry_notification.lead_time_days_v1';

  static const int defaultLeadTimeDays = 30;

  static final ValueNotifier<ExpiryNotificationConfig> value = ValueNotifier(
    const ExpiryNotificationConfig(leadTimeDays: defaultLeadTimeDays),
  );

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getInt(_prefsKeyLeadTimeDays) ?? defaultLeadTimeDays;
      value.value = value.value.copyWith(leadTimeDays: _clampDays(days));
    } catch (_) {
      // Best-effort; keep defaults.
    }
  }

  static int _clampDays(int raw) {
    // Clamp to reasonable range: 1-90 days
    return raw.clamp(1, 90);
  }

  static Future<void> setLeadTimeDays(int days) async {
    final next = _clampDays(days);
    value.value = value.value.copyWith(leadTimeDays: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyLeadTimeDays, next);
    } catch (_) {
      // Best-effort.
    }
  }
}
