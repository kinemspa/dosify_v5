// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/hive/hive_migration_manager.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_status_change_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';

class HiveBootstrap {
  static Future<void> init() async {
    print('HiveBootstrap: initFlutter...');
    await Hive.initFlutter();
    _registerAdapters();

    // Open medications box
    await _openBoxWithRetry<Medication>('medications');

    // Run migrations if needed
    print('HiveBootstrap: Running migrations...');
    await HiveMigrationManager.migrate();

    // Validate migration was successful
    final isValid = await HiveMigrationManager.validateMigration();
    if (!isValid) {
      print('WARNING: Hive migration validation failed');
    }

    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(ScheduleAdapter());
    await _openBoxWithRetry<Schedule>('schedules');

    // Dose logs (persistent history even after schedule/medication deletion)
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(DoseLogAdapter());
    if (!Hive.isAdapterRegistered(42))
      Hive.registerAdapter(DoseActionAdapter());
    await _openBoxWithRetry<DoseLog>('dose_logs');

    // Dose status change logs (audit trail for status edits/reverts)
    if (!Hive.isAdapterRegistered(45)) {
      Hive.registerAdapter(DoseStatusChangeLogAdapter());
    }
    await _openBoxWithRetry<DoseStatusChangeLog>('dose_status_change_logs');

    // Supplies
    if (!Hive.isAdapterRegistered(50)) Hive.registerAdapter(SupplyAdapter());
    if (!Hive.isAdapterRegistered(52))
      Hive.registerAdapter(SupplyTypeAdapter());
    if (!Hive.isAdapterRegistered(53))
      Hive.registerAdapter(SupplyUnitAdapter());
    if (!Hive.isAdapterRegistered(51))
      Hive.registerAdapter(StockMovementAdapter());
    if (!Hive.isAdapterRegistered(54))
      Hive.registerAdapter(MovementReasonAdapter());

    await _openBoxWithRetry<Supply>('supplies');
    await _openBoxWithRetry<StockMovement>('stock_movements');

    // Inventory logs (refills, adjustments, usage tracking)
    if (!Hive.isAdapterRegistered(43))
      Hive.registerAdapter(InventoryLogAdapter());
    if (!Hive.isAdapterRegistered(44))
      Hive.registerAdapter(InventoryChangeTypeAdapter());
    await _openBoxWithRetry<InventoryLog>('inventory_logs');

    // Saved reconstitution calculations
    if (!Hive.isAdapterRegistered(60)) {
      Hive.registerAdapter(SavedReconstitutionCalculationAdapter());
    }
    await _openBoxWithRetry<SavedReconstitutionCalculation>(
      'saved_reconstitutions',
    );

    print('HiveBootstrap: Initialization complete');
  }

  static Future<Box<T>> _openBoxWithRetry<T>(String name) async {
    try {
      print('HiveBootstrap: Opening box "$name"...');
      // Increased timeout to 15 seconds - slow devices need more time
      return await Hive.openBox<T>(name).timeout(const Duration(seconds: 15));
    } catch (e) {
      print('HiveBootstrap: Failed to open box "$name" (Error: $e).');

      // Only delete and recreate on actual corruption errors (HiveError)
      // Do NOT delete on timeouts or other transient errors - that causes data loss!
      if (e is HiveError) {
        print(
          'HiveBootstrap: Detected HiveError (corruption). Attempting recovery by deleting box...',
        );
        try {
          await Hive.deleteBoxFromDisk(name);
          print(
            'HiveBootstrap: Deleted corrupted box "$name". Retrying open...',
          );
          return await Hive.openBox<T>(name);
        } catch (e2) {
          print(
            'HiveBootstrap: CRITICAL ERROR: Could not recover box "$name": $e2',
          );
          rethrow;
        }
      } else {
        // For timeouts and other errors, just retry without deleting
        print('HiveBootstrap: Retrying open without deletion...');
        try {
          return await Hive.openBox<T>(name);
        } catch (e2) {
          print(
            'HiveBootstrap: CRITICAL ERROR: Could not open box "$name": $e2',
          );
          rethrow;
        }
      }
    }
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UnitAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(StockUnitAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(MedicationFormAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(VolumeUnitAdapter());
    if (!Hive.isAdapterRegistered(10))
      Hive.registerAdapter(MedicationAdapter());
  }
}
