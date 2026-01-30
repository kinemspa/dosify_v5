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

    // Open boxes used by the action sheet. They can stay empty for this test.
    await Hive.openBox<Schedule>('schedules');
    await Hive.openBox<Medication>('medications');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir != null && hiveDir!.existsSync()) {
      hiveDir!.deleteSync(recursive: true);
    }
  });

  testWidgets('DoseActionSheet shows Scrollbar and taken tick icon', (
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
      action: DoseAction.taken,
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoseActionSheet(
            dose: dose,
            onMarkTaken: (_) async {},
            onSnooze: (_) async {},
            onSkip: (_) async {},
            onDelete: (_) async {},
            presentation: DoseActionSheetPresentation.bottomSheet,
            initialStatus: DoseStatus.taken,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollbarFinder = find.byType(Scrollbar);
    expect(scrollbarFinder, findsOneWidget);

    final scrollbar = tester.widget<Scrollbar>(scrollbarFinder);
    expect(scrollbar.thumbVisibility, isTrue);

    // Date button icon switches to a thicker tick when status is Taken.
    await tester.scrollUntilVisible(find.text('Date & Time'), 200);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
  });
}
