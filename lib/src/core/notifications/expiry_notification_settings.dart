import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ExpiryNotificationConfig {
  const ExpiryNotificationConfig({required this.leadDays});

  final int leadDays;

  ExpiryNotificationConfig copyWith({int? leadDays}) {
    return ExpiryNotificationConfig(leadDays: leadDays ?? this.leadDays);
  }
}

class ExpiryNotificationSettings {
  const ExpiryNotificationSettings._();

  static const String _prefsKeyLeadDays = 'expiry_notifications.lead_days_v1';

  static const int defaultLeadDays = 14;
  static const List<int> allowedLeadDays = <int>[7, 14, 30];

  static final ValueNotifier<ExpiryNotificationConfig> value = ValueNotifier(
    const ExpiryNotificationConfig(leadDays: defaultLeadDays),
  );

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getInt(_prefsKeyLeadDays) ?? defaultLeadDays;
      value.value = value.value.copyWith(leadDays: _normalize(raw));
    } catch (_) {
      // Best-effort; keep defaults.
    }
  }

  static int _normalize(int raw) {
    if (allowedLeadDays.contains(raw)) return raw;
    return defaultLeadDays;
  }

  static Future<void> setLeadDays(int days) async {
    final next = _normalize(days);
    value.value = value.value.copyWith(leadDays: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyLeadDays, next);
    } catch (_) {
      // Best-effort.
    }
  }
}
