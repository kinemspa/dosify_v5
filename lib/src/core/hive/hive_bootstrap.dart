// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/hive/hive_migration_manager.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';

class HiveBootstrap {
  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();

    // Open medications box
    await Hive.openBox<Medication>('medications');

    // Run migrations if needed
    await HiveMigrationManager.migrate();

    // Validate migration was successful
    final isValid = await HiveMigrationManager.validateMigration();
    if (!isValid) {
      print('WARNING: Hive migration validation failed');
    }

    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(ScheduleAdapter());
    await Hive.openBox<Schedule>('schedules');

    // Dose logs (persistent history even after schedule/medication deletion)
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(DoseLogAdapter());
    if (!Hive.isAdapterRegistered(42))
      Hive.registerAdapter(DoseActionAdapter());
    await Hive.openBox<DoseLog>('dose_logs');

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
    await Hive.openBox<Supply>('supplies');
    await Hive.openBox<StockMovement>('stock_movements');
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UnitAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(StockUnitAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(MedicationFormAdapter());
    if (!Hive.isAdapterRegistered(10))
      Hive.registerAdapter(MedicationAdapter());
  }
}
