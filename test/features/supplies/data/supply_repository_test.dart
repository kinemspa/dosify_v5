import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dosifi_v5/src/features/supplies/data/supply_repository.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('dosifi_test_hive_supplies');
    Hive.init(dir.path);

    if (!Hive.isAdapterRegistered(50)) Hive.registerAdapter(SupplyAdapter());
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(StockMovementAdapter());
    }
    if (!Hive.isAdapterRegistered(52)) {
      Hive.registerAdapter(SupplyTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(53)) {
      Hive.registerAdapter(SupplyUnitAdapter());
    }
    if (!Hive.isAdapterRegistered(54)) {
      Hive.registerAdapter(MovementReasonAdapter());
    }

    await Hive.openBox<Supply>(SupplyRepository.suppliesBoxName);
    await Hive.openBox<StockMovement>(SupplyRepository.movementsBoxName);
  });

  tearDown(() async {
    await Hive.box<StockMovement>(SupplyRepository.movementsBoxName).clear();
    await Hive.box<Supply>(SupplyRepository.suppliesBoxName).clear();

    await Hive.box<StockMovement>(SupplyRepository.movementsBoxName).close();
    await Hive.box<Supply>(SupplyRepository.suppliesBoxName).close();
  });

  test('movementsFor returns movements sorted by time ascending', () async {
    final repo = SupplyRepository();
    const supplyId = 'sup_1';

    await repo.upsert(
      Supply(
        id: supplyId,
        name: 'Needles',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      ),
    );

    final t1 = DateTime(2025, 1, 1, 10, 0);
    final t2 = DateTime(2025, 1, 1, 11, 0);
    final t3 = DateTime(2025, 1, 1, 12, 0);

    await repo.addMovement(
      StockMovement(
        id: 'm2',
        supplyId: supplyId,
        delta: 10,
        reason: MovementReason.purchase,
        at: t2,
      ),
    );
    await repo.addMovement(
      StockMovement(
        id: 'm1',
        supplyId: supplyId,
        delta: -1,
        reason: MovementReason.used,
        at: t1,
      ),
    );
    await repo.addMovement(
      StockMovement(
        id: 'm3',
        supplyId: supplyId,
        delta: -2,
        reason: MovementReason.used,
        at: t3,
      ),
    );

    final movements = repo.movementsFor(supplyId);
    expect(movements.map((m) => m.id).toList(), ['m1', 'm2', 'm3']);
  });

  test('currentStock sums deltas including negative movements', () async {
    final repo = SupplyRepository();
    const supplyId = 'sup_2';

    await repo.upsert(
      Supply(
        id: supplyId,
        name: 'Swabs',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      ),
    );

    await repo.addMovement(
      StockMovement(
        id: 'p1',
        supplyId: supplyId,
        delta: 20,
        reason: MovementReason.purchase,
      ),
    );
    await repo.addMovement(
      StockMovement(
        id: 'u1',
        supplyId: supplyId,
        delta: -3,
        reason: MovementReason.used,
      ),
    );
    await repo.addMovement(
      StockMovement(
        id: 'c1',
        supplyId: supplyId,
        delta: -2,
        reason: MovementReason.correction,
      ),
    );

    expect(repo.currentStock(supplyId), 15);
  });

  test('isLowStock returns true when current stock is <= threshold', () async {
    final repo = SupplyRepository();
    const supplyId = 'sup_3';

    final supply = Supply(
      id: supplyId,
      name: 'Alcohol wipes',
      type: SupplyType.item,
      unit: SupplyUnit.pcs,
      reorderThreshold: 10,
    );
    await repo.upsert(supply);

    await repo.addMovement(
      StockMovement(
        id: 'p1',
        supplyId: supplyId,
        delta: 10,
        reason: MovementReason.purchase,
      ),
    );

    expect(repo.isLowStock(supply), isTrue);

    await repo.addMovement(
      StockMovement(
        id: 'p2',
        supplyId: supplyId,
        delta: 1,
        reason: MovementReason.purchase,
      ),
    );

    expect(repo.isLowStock(supply), isFalse);
  });

  test('isExpiringSoon uses a strict before-threshold check', () async {
    final repo = SupplyRepository();

    final now = DateTime(2025, 1, 1);

    final expiringSoon = Supply(
      id: 'sup_4',
      name: 'Bacteriostatic water',
      type: SupplyType.fluid,
      unit: SupplyUnit.ml,
      expiry: now.add(const Duration(days: 29)),
    );

    final notExpiringSoon = Supply(
      id: 'sup_5',
      name: 'Saline',
      type: SupplyType.fluid,
      unit: SupplyUnit.ml,
      expiry: now.add(const Duration(days: 30)),
    );

    expect(repo.isExpiringSoon(expiringSoon, now: now), isTrue);
    expect(repo.isExpiringSoon(notExpiringSoon, now: now), isFalse);
  });
}
