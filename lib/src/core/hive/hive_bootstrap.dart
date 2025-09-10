import 'package:hive_flutter/hive_flutter.dart';
import '../../features/medications/domain/enums.dart';
import '../../features/medications/domain/medication.dart';
import '../../features/schedules/domain/schedule.dart';
import '../../features/supplies/domain/supply.dart';
import '../../features/supplies/domain/stock_movement.dart';

class HiveBootstrap {
  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await Hive.openBox<Medication>('medications');
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(ScheduleAdapter());
    await Hive.openBox<Schedule>('schedules');

    // Supplies
    if (!Hive.isAdapterRegistered(50)) Hive.registerAdapter(SupplyAdapter());
    if (!Hive.isAdapterRegistered(52)) Hive.registerAdapter(SupplyTypeAdapter());
    if (!Hive.isAdapterRegistered(53)) Hive.registerAdapter(SupplyUnitAdapter());
    if (!Hive.isAdapterRegistered(51)) Hive.registerAdapter(StockMovementAdapter());
    if (!Hive.isAdapterRegistered(54)) Hive.registerAdapter(MovementReasonAdapter());
    await Hive.openBox<Supply>('supplies');
    await Hive.openBox<StockMovement>('stock_movements');
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UnitAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(StockUnitAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MedicationFormAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(MedicationAdapter());
  }
}

