// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/hive/hive_box_safe_write.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';

class SupplyRepository {
  static const suppliesBoxName = 'supplies';
  static const movementsBoxName = 'stock_movements';

  static const Duration defaultExpiringSoonWithin = Duration(days: 30);

  Box<Supply> get _supplies => Hive.box<Supply>(suppliesBoxName);
  Box<StockMovement> get _movements =>
      Hive.box<StockMovement>(movementsBoxName);

  Future<void> upsert(Supply s) async {
    await _supplies.putSafe(s.id, s);
  }

  Future<void> delete(String id) async {
    // delete movements first
    final toDelete = _movements.values
        .where((m) => m.supplyId == id)
        .map((m) => m.id)
        .toList();
    for (final mid in toDelete) {
      await _movements.deleteSafe(mid);
    }
    await _supplies.deleteSafe(id);
  }

  List<Supply> allSupplies() => _supplies.values.toList(growable: false);

  Future<void> addMovement(StockMovement m) async {
    await _movements.putSafe(m.id, m);
  }

  List<StockMovement> movementsFor(String supplyId) {
    return _movements.values
        .where((m) => m.supplyId == supplyId)
        .toList(growable: false)
      ..sort((a, b) => a.at.compareTo(b.at));
  }

  double currentStock(String supplyId) {
    final supply = _supplies.get(supplyId);
    if (supply == null) return 0;
    final sum = _movements.values
        .where((m) => m.supplyId == supplyId)
        .fold<double>(0, (acc, m) => acc + m.delta);
    return sum;
  }

  bool isLowStock(Supply s) {
    if (s.reorderThreshold == null) return false;
    final cur = currentStock(s.id);
    return cur <= s.reorderThreshold!;
  }

  bool isExpiringSoon(
    Supply s, {
    DateTime? now,
    Duration within = defaultExpiringSoonWithin,
  }) {
    final expiry = s.expiry;
    if (expiry == null) return false;
    final base = now ?? DateTime.now();
    return expiry.isBefore(base.add(within));
  }
}
