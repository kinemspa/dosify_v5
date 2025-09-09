import 'package:hive_flutter/hive_flutter.dart';
import '../../features/medications/domain/enums.dart';
import '../../features/medications/domain/medication.dart';

class HiveBootstrap {
  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await Hive.openBox<Medication>('medications');
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UnitAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(StockUnitAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MedicationFormAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(MedicationAdapter());
  }
}

