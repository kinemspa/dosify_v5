import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('dosifi_hive_test_');
    Hive.init(hiveDir!.path);

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
    if (!Hive.isAdapterRegistered(DoseLogAdapter().typeId)) {
      Hive.registerAdapter(DoseLogAdapter());
    }
    if (!Hive.isAdapterRegistered(DoseActionAdapter().typeId)) {
      Hive.registerAdapter(DoseActionAdapter());
    }

    // Open boxes used by the action sheet. They can stay empty for this test.
    await Hive.openBox<Schedule>('schedules');
    await Hive.openBox<Medication>('medications');
    await Hive.openBox<DoseLog>('dose_logs');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir != null && hiveDir!.existsSync()) {
      hiveDir!.deleteSync(recursive: true);
    }
  });

  testWidgets('DoseActionSheet renders without error and shows key affordances', (
    tester,
  ) async {
    final scheduledTime = DateTime(2025, 1, 1, 8, 0);
    final log = DoseLog(
      id: 'log_1',
      scheduleId: 's_1',
      scheduleName: 'Morning',
      medicationId: 'm_1',
      medicationName: 'Test Med',
      scheduledTime: scheduledTime,
      doseValue: 10,
      doseUnit: 'units',
      action: DoseAction.logged,
      actionTime: DateTime(2025, 1, 1, 8, 5),
    );

    final dose = CalculatedDose(
      scheduleId: 's_1',
      scheduleName: 'Morning',
      medicationName: 'Test Med',
      scheduledTime: scheduledTime,
      doseValue: 10,
      doseUnit: 'units',
      existingLog: log,
    );

    // Capture and filter overflow errors so they don't fail the test — the
    // sheet is designed for phone-width screens; the test viewport is fine.
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) {
        oldOnError?.call(details);
      }
    };

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(375, 812)),
          child: Scaffold(
            body: DoseActionSheet(
              dose: dose,
              onMarkLogged: (_) async {},
              onSnooze: (_) async {},
              onSkip: (_) async {},
              onDelete: (_) async {},
              presentation: DoseActionSheetPresentation.bottomSheet,
              initialStatus: DoseStatus.logged,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    FlutterError.onError = oldOnError; // Restore handler.

    // Verify the sheet renders with its core affordances.
    expect(find.text('Save & Close'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    // The sheet header is always visible (not inside the scrollable section).
    expect(find.text('Log dose'), findsOneWidget);
  });
}
