import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/data/supply_repository.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing
    await Hive.init('./test_hive');
    Hive.registerAdapter(SupplyAdapter());
    Hive.registerAdapter(SupplyTypeAdapter());
    Hive.registerAdapter(SupplyUnitAdapter());
    Hive.registerAdapter(StockMovementAdapter());
    Hive.registerAdapter(MovementReasonAdapter());
  });

  setUp(() async {
    // Open boxes for each test
    await Hive.openBox<Supply>(SupplyRepository.suppliesBoxName);
    await Hive.openBox<StockMovement>(SupplyRepository.movementsBoxName);
  });

  tearDown(() async {
    // Clear boxes after each test
    final suppliesBox = Hive.box<Supply>(SupplyRepository.suppliesBoxName);
    final movementsBox = Hive.box<StockMovement>(
      SupplyRepository.movementsBoxName,
    );
    await suppliesBox.clear();
    await movementsBox.clear();
    await suppliesBox.close();
    await movementsBox.close();
  });

  tearDownAll(() async {
    // Clean up Hive
    await Hive.deleteFromDisk();
  });

  group('Stock Aggregation', () {
    test('calculates current stock from movements', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup1',
        name: 'Test Supply',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply);

      // Add movements
      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup1',
        delta: 100,
        reason: MovementReason.purchase,
      ));
      await repo.addMovement(StockMovement(
        id: 'mv2',
        supplyId: 'sup1',
        delta: -20,
        reason: MovementReason.used,
      ));
      await repo.addMovement(StockMovement(
        id: 'mv3',
        supplyId: 'sup1',
        delta: 50,
        reason: MovementReason.purchase,
      ));

      final current = repo.currentStock('sup1');
      expect(current, equals(130.0)); // 100 - 20 + 50
    });

    test('returns zero for supply with no movements', () {
      final repo = SupplyRepository();
      final current = repo.currentStock('nonexistent');
      expect(current, equals(0.0));
    });

    test('handles negative deltas correctly', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup2',
        name: 'Negative Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply);

      // Add purchase
      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup2',
        delta: 50,
        reason: MovementReason.purchase,
      ));
      // Use more than available
      await repo.addMovement(StockMovement(
        id: 'mv2',
        supplyId: 'sup2',
        delta: -75,
        reason: MovementReason.used,
      ));

      final current = repo.currentStock('sup2');
      expect(current, equals(-25.0)); // 50 - 75 = -25 (allows negative)
    });

    test('handles correction movements', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup3',
        name: 'Correction Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply);

      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup3',
        delta: 100,
        reason: MovementReason.purchase,
      ));
      // Correction to fix inventory count
      await repo.addMovement(StockMovement(
        id: 'mv2',
        supplyId: 'sup3',
        delta: -10,
        reason: MovementReason.correction,
        note: 'Physical count adjustment',
      ));

      final current = repo.currentStock('sup3');
      expect(current, equals(90.0));
    });

    test('handles decimal quantities for fluids', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup4',
        name: 'Fluid Supply',
        type: SupplyType.fluid,
        unit: SupplyUnit.ml,
      );
      await repo.upsert(supply);

      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup4',
        delta: 150.5,
        reason: MovementReason.purchase,
      ));
      await repo.addMovement(StockMovement(
        id: 'mv2',
        supplyId: 'sup4',
        delta: -25.75,
        reason: MovementReason.used,
      ));

      final current = repo.currentStock('sup4');
      expect(current, closeTo(124.75, 0.001));
    });
  });

  group('Movements Ordering', () {
    test('orders movements chronologically', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup5',
        name: 'Ordering Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply);

      final now = DateTime.now();
      // Add movements out of order
      await repo.addMovement(StockMovement(
        id: 'mv3',
        supplyId: 'sup5',
        delta: 30,
        reason: MovementReason.purchase,
        at: now.add(const Duration(hours: 2)),
      ));
      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup5',
        delta: 10,
        reason: MovementReason.purchase,
        at: now,
      ));
      await repo.addMovement(StockMovement(
        id: 'mv2',
        supplyId: 'sup5',
        delta: 20,
        reason: MovementReason.purchase,
        at: now.add(const Duration(hours: 1)),
      ));

      final movements = repo.movementsFor('sup5');
      expect(movements.length, equals(3));
      expect(movements[0].id, equals('mv1'));
      expect(movements[1].id, equals('mv2'));
      expect(movements[2].id, equals('mv3'));
      expect(movements[0].at.isBefore(movements[1].at), isTrue);
      expect(movements[1].at.isBefore(movements[2].at), isTrue);
    });

    test('handles movements at same timestamp', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup6',
        name: 'Same Time Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply);

      final now = DateTime.now();
      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup6',
        delta: 10,
        reason: MovementReason.purchase,
        at: now,
      ));
      await repo.addMovement(StockMovement(
        id: 'mv2',
        supplyId: 'sup6',
        delta: 20,
        reason: MovementReason.purchase,
        at: now,
      ));

      final current = repo.currentStock('sup6');
      expect(current, equals(30.0)); // Both movements counted
    });
  });

  group('Low Stock Thresholds', () {
    test('identifies low stock when below threshold', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup7',
        name: 'Low Stock Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
        reorderThreshold: 50.0,
      );
      await repo.upsert(supply);

      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup7',
        delta: 30,
        reason: MovementReason.purchase,
      ));

      expect(repo.isLowStock(supply), isTrue);
    });

    test('identifies low stock when exactly at threshold', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup8',
        name: 'At Threshold Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
        reorderThreshold: 50.0,
      );
      await repo.upsert(supply);

      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup8',
        delta: 50,
        reason: MovementReason.purchase,
      ));

      expect(repo.isLowStock(supply), isTrue); // At threshold is considered low
    });

    test('does not flag as low stock when above threshold', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup9',
        name: 'Good Stock Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
        reorderThreshold: 50.0,
      );
      await repo.upsert(supply);

      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup9',
        delta: 100,
        reason: MovementReason.purchase,
      ));

      expect(repo.isLowStock(supply), isFalse);
    });

    test('returns false for supply without threshold', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup10',
        name: 'No Threshold Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply);

      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup10',
        delta: 5,
        reason: MovementReason.purchase,
      ));

      expect(repo.isLowStock(supply), isFalse);
    });

    test('handles zero threshold', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup11',
        name: 'Zero Threshold Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
        reorderThreshold: 0.0,
      );
      await repo.upsert(supply);

      expect(repo.isLowStock(supply), isFalse); // Zero threshold doesn't trigger
    });
  });

  group('Cascade Delete', () {
    test('deletes associated movements when supply is deleted', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup12',
        name: 'Delete Test',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply);

      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup12',
        delta: 100,
        reason: MovementReason.purchase,
      ));
      await repo.addMovement(StockMovement(
        id: 'mv2',
        supplyId: 'sup12',
        delta: -20,
        reason: MovementReason.used,
      ));

      // Verify movements exist
      expect(repo.movementsFor('sup12').length, equals(2));

      // Delete supply
      await repo.delete('sup12');

      // Verify supply is gone
      expect(repo.allSupplies().where((s) => s.id == 'sup12').isEmpty, isTrue);

      // Verify movements are gone
      expect(repo.movementsFor('sup12').isEmpty, isTrue);
    });
  });

  group('Expiring Soon Logic', () {
    test('identifies supplies expiring within 30 days', () {
      final now = DateTime.now();
      final expiresIn15Days = now.add(const Duration(days: 15));
      
      final supply = Supply(
        id: 'sup13',
        name: 'Expiring Soon',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
        expiry: expiresIn15Days,
      );

      final threshold = now.add(const Duration(days: 30));
      expect(supply.expiry!.isBefore(threshold), isTrue);
    });

    test('does not flag supplies expiring after 30 days', () {
      final now = DateTime.now();
      final expiresIn60Days = now.add(const Duration(days: 60));
      
      final supply = Supply(
        id: 'sup14',
        name: 'Not Expiring Soon',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
        expiry: expiresIn60Days,
      );

      final threshold = now.add(const Duration(days: 30));
      expect(supply.expiry!.isBefore(threshold), isFalse);
    });

    test('handles supplies with no expiry date', () {
      final supply = Supply(
        id: 'sup15',
        name: 'No Expiry',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );

      expect(supply.expiry, isNull);
    });

    test('identifies already expired supplies', () {
      final now = DateTime.now();
      final expired = now.subtract(const Duration(days: 1));
      
      final supply = Supply(
        id: 'sup16',
        name: 'Expired',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
        expiry: expired,
      );

      final threshold = now.add(const Duration(days: 30));
      expect(supply.expiry!.isBefore(threshold), isTrue);
      expect(supply.expiry!.isBefore(now), isTrue);
    });
  });

  group('Edge Cases', () {
    test('handles empty movements list', () async {
      final repo = SupplyRepository();
      final supply = Supply(
        id: 'sup17',
        name: 'Empty Movements',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply);

      final current = repo.currentStock('sup17');
      expect(current, equals(0.0));

      final movements = repo.movementsFor('sup17');
      expect(movements.isEmpty, isTrue);
    });

    test('handles multiple supplies with same movements pattern', () async {
      final repo = SupplyRepository();
      final supply1 = Supply(
        id: 'sup18',
        name: 'Supply 1',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      final supply2 = Supply(
        id: 'sup19',
        name: 'Supply 2',
        type: SupplyType.item,
        unit: SupplyUnit.pcs,
      );
      await repo.upsert(supply1);
      await repo.upsert(supply2);

      await repo.addMovement(StockMovement(
        id: 'mv1',
        supplyId: 'sup18',
        delta: 100,
        reason: MovementReason.purchase,
      ));
      await repo.addMovement(StockMovement(
        id: 'mv2',
        supplyId: 'sup19',
        delta: 200,
        reason: MovementReason.purchase,
      ));

      expect(repo.currentStock('sup18'), equals(100.0));
      expect(repo.currentStock('sup19'), equals(200.0));
      expect(repo.movementsFor('sup18').length, equals(1));
      expect(repo.movementsFor('sup19').length, equals(1));
    });
  });
}
