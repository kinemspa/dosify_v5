import 'package:shared_preferences/shared_preferences.dart';

class MonetizationMetricsService {
  static const String _prefix = 'monetization_metrics';

  static Future<void> trackPaywallShown() async {
    await _increment('paywall_shown');
  }

  static Future<void> trackPurchaseStarted() async {
    await _increment('purchase_started');
  }

  static Future<void> trackPurchaseSuccess() async {
    await _increment('purchase_success');
  }

  static Future<void> trackRestoreSuccess() async {
    await _increment('restore_success');
  }

  static Future<void> trackLimitHit() async {
    await _increment('limit_hit');
  }

  static Future<void> _increment(String eventName) async {
    final prefs = await SharedPreferences.getInstance();
    final countKey = '$_prefix.$eventName.count';
    final timestampKey = '$_prefix.$eventName.last_utc';

    final current = prefs.getInt(countKey) ?? 0;
    await prefs.setInt(countKey, current + 1);
    await prefs.setString(
      timestampKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
