import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_detail_page.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

ThemeData _testTheme() {
  const primarySeed = kDetailHeaderGradientStart;
  final scheme = ColorScheme.fromSeed(
    seedColor: primarySeed,
  ).copyWith(primary: primarySeed);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

Future<List<FlutterErrorDetails>> _captureFlutterErrors(
  Future<void> Function() action,
) async {
  final errors = <FlutterErrorDetails>[];
  final oldHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details);
  };

  try {
    await action();
  } finally {
    FlutterError.onError = oldHandler;
  }
  return errors;
}

bool _isOverflowError(FlutterErrorDetails details) {
  final message = details.exceptionAsString();
  return message.contains('A RenderFlex overflowed') ||
      message.contains('overflowed by');
}

void _registerHiveAdaptersIfNeeded() {
  if (!Hive.isAdapterRegistered(UnitAdapter().typeId)) {
    Hive.registerAdapter(UnitAdapter());
  }
  if (!Hive.isAdapterRegistered(StockUnitAdapter().typeId)) {
    Hive.registerAdapter(StockUnitAdapter());
  }
  if (!Hive.isAdapterRegistered(MedicationFormAdapter().typeId)) {
    Hive.registerAdapter(MedicationFormAdapter());
  }
  if (!Hive.isAdapterRegistered(VolumeUnitAdapter().typeId)) {
    Hive.registerAdapter(VolumeUnitAdapter());
  }
  if (!Hive.isAdapterRegistered(MedicationAdapter().typeId)) {
    Hive.registerAdapter(MedicationAdapter());
  }
  if (!Hive.isAdapterRegistered(ScheduleAdapter().typeId)) {
    Hive.registerAdapter(ScheduleAdapter());
  }
  if (!Hive.isAdapterRegistered(DoseActionAdapter().typeId)) {
    Hive.registerAdapter(DoseActionAdapter());
  }
  if (!Hive.isAdapterRegistered(DoseLogAdapter().typeId)) {
    Hive.registerAdapter(DoseLogAdapter());
  }
  if (!Hive.isAdapterRegistered(InventoryChangeTypeAdapter().typeId)) {
    Hive.registerAdapter(InventoryChangeTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(InventoryLogAdapter().typeId)) {
    Hive.registerAdapter(InventoryLogAdapter());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    hiveDir = await Directory.systemTemp.createTemp('dosifi_hive_test_');
    Hive.init(hiveDir!.path);

    _registerHiveAdaptersIfNeeded();

    await Hive.openBox<Medication>('medications');
    await Hive.openBox<Schedule>('schedules');
    await Hive.openBox<DoseLog>('dose_logs');
    await Hive.openBox<InventoryLog>('inventory_logs');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir != null && hiveDir!.existsSync()) {
      hiveDir!.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'MedicationDetailPage does not overflow at compact width with large text',
    (WidgetTester tester) async {
      final med = Medication(
        id: 'm_1',
        form: MedicationForm.tablet,
        name:
            'Extremely Long Medication Name That Should Never Overflow The Header Even On Narrow Screens',
        manufacturer:
            'Very Long Manufacturer Name That Also Should Not Overflow Or Clip Badly',
        strengthValue: 100,
        strengthUnit: Unit.mg,
        stockValue: 30,
        stockUnit: StockUnit.tablets,
      );

      final schedule = Schedule(
        id: 's_1',
        name: 'Morning dose',
        medicationName: med.name,
        doseValue: 1,
        doseUnit: 'tablet',
        minutesOfDay: 8 * 60,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
        medicationId: med.id,
        active: true,
      );

      await Hive.box<Medication>('medications').put(med.id, med);
      await Hive.box<Schedule>('schedules').put(schedule.id, schedule);

      final errors = await _captureFlutterErrors(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: _testTheme(),
            home: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 320),
                child: ProviderScope(
                  child: MediaQuery(
                    data: const MediaQueryData(
                      size: Size(320, 900),
                      textScaler: TextScaler.linear(1.5),
                    ),
                    child: const MedicationDetailPage(medicationId: 'm_1'),
                  ),
                ),
              ),
            ),
          ),
        );

        // MedicationDetailPage contains cards with internal timers/animations.
        // Avoid pumpAndSettle() hanging; bounded pumps are enough to surface
        // layout overflows.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
      });

      final overflowErrors = errors.where(_isOverflowError);
      expect(overflowErrors, isEmpty);
    },
  );
}
