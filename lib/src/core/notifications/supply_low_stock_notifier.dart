// Flutter/Dart imports:
import 'dart:async';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';

/// Fires a low-stock push notification the first time a supply stock level
/// crosses below its reorder threshold, and resets the flag when stock rises
/// back above the threshold so future crossings will notify again.
class SupplyLowStockNotifier {
  const SupplyLowStockNotifier._();

  static const String _prefsPrefix = 'supply_low_stock.notified.';

  static Future<void> handleStockChange({
    required Supply supply,
    required double stockBefore,
    required double stockAfter,
  }) async {
    final threshold = supply.reorderThreshold;
    if (threshold == null || threshold <= 0) return;

    final wasLow = stockBefore <= threshold;
    final isLow = stockAfter <= threshold;

    if (!isLow) {
      // Stock rose above threshold — reset so next crossing notifies again.
      await _setNotified(supply.id, false);
      return;
    }

    final alreadyNotified = await _getNotified(supply.id);
    if (wasLow || alreadyNotified) {
      // Already in low-stock territory; avoid spamming.
      await _setNotified(supply.id, true);
      return;
    }

    // First time crossing below threshold — fire notification.
    final unit = switch (supply.unit) {
      SupplyUnit.pcs => 'pcs',
      SupplyUnit.ml => 'mL',
      SupplyUnit.l => 'L',
    };
    final stockFmt = stockAfter % 1 == 0
        ? stockAfter.toInt().toString()
        : stockAfter.toStringAsFixed(1);

    final id = NotificationService.stableIdForKey('supply_low_stock|${supply.id}');
    await NotificationService.showLowStockAlert(
      id,
      title: 'Low supply',
      body: '${supply.name} is running low ($stockFmt $unit remaining).',
      payload: 'supply_low_stock:${supply.id}',
    );

    await _setNotified(supply.id, true);
  }

  static Future<bool> _getNotified(String supplyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefsPrefix$supplyId') ?? false;
  }

  static Future<void> _setNotified(String supplyId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsPrefix$supplyId', value);
  }
}
