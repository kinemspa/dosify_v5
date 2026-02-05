// Flutter/Dart imports:
import 'dart:async';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

class LowStockNotifier {
  const LowStockNotifier._();

  static const String _prefsPrefix = 'low_stock.notified.';

  static Future<void> handleStockChange({
    required Medication before,
    required Medication after,
  }) async {
    if (before.id != after.id) return;

    final threshold = _effectiveThreshold(after);
    if (threshold == null || threshold <= 0) return;

    final enabled = after.lowStockEnabled;
    if (!enabled) {
      await _setNotified(after.id, false);
      return;
    }

    final beforeValue = _effectiveStockValue(before);
    final afterValue = _effectiveStockValue(after);

    final wasLow = beforeValue <= threshold;
    final isLow = afterValue <= threshold;

    // Track state so we can notify on the boundary crossing.
    if (!isLow) {
      await _setNotified(after.id, false);
      return;
    }

    final alreadyNotified = await _getNotified(after.id);
    if (wasLow || alreadyNotified) {
      // Already in low-stock territory; don't spam.
      await _setNotified(after.id, true);
      return;
    }

    final id = NotificationService.stableIdForKey('low_stock|${after.id}');
    final title = 'Low stock';
    final body = '${after.name} is low on stock.';

    await NotificationService.showLowStockAlert(
      id,
      title: title,
      body: body,
      payload: 'low_stock:${after.id}',
    );

    await _setNotified(after.id, true);
  }

  static double _effectiveStockValue(Medication med) {
    if (med.stockUnit == StockUnit.multiDoseVials) {
      return med.activeVialVolume ?? 0.0;
    }
    return med.stockValue;
  }

  static double? _effectiveThreshold(Medication med) {
    if (med.stockUnit == StockUnit.multiDoseVials) {
      return med.activeVialLowStockMl ?? med.lowStockVialVolumeThresholdMl;
    }
    return med.lowStockThreshold;
  }

  static Future<bool> _getNotified(String medicationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefsPrefix$medicationId') ?? false;
  }

  static Future<void> _setNotified(String medicationId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsPrefix$medicationId', value);
  }
}
