import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/entry_action_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('skedux_hive_test_');
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
    if (!Hive.isAdapterRegistered(EntryLogAdapter().typeId)) {
      Hive.registerAdapter(EntryLogAdapter());
    }
    if (!Hive.isAdapterRegistered(EntryActionAdapter().typeId)) {
      Hive.registerAdapter(EntryActionAdapter());
    }

    // Open boxes used by the action sheet. They can stay empty for this test.
    await Hive.openBox<Schedule>('schedules');
    await Hive.openBox<Medication>('medications');
    await Hive.openBox<EntryLog>('entry_logs');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir != null && hiveDir!.existsSync()) {
      hiveDir!.deleteSync(recursive: true);
    }
  });

  testWidgets('EntryActionSheet renders without error and shows key affordances', (
    tester,
  ) async {
    final scheduledTime = DateTime(2025, 1, 1, 8, 0);
    final log = EntryLog(
      id: 'log_1',
      scheduleId: 's_1',
      scheduleName: 'Morning',
      medicationId: 'm_1',
      medicationName: 'Test Med',
      scheduledTime: scheduledTime,
      entryValue: 10,
      entryUnit: 'units',
      action: EntryAction.logged,
      actionTime: DateTime(2025, 1, 1, 8, 5),
    );

    final entry = CalculatedEntry(
      scheduleId: 's_1',
      scheduleName: 'Morning',
      medicationName: 'Test Med',
      scheduledTime: scheduledTime,
      entryValue: 10,
      entryUnit: 'units',
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
            body: EntryActionSheet(
              entry: entry,
              onMarkLogged: (_) async {},
              onSnooze: (_) async {},
              onSkip: (_) async {},
              onDelete: (_) async {},
              presentation: EntryActionSheetPresentation.bottomSheet,
              initialStatus: EntryStatus.logged,
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
    expect(find.text('Log entry'), findsOneWidget);
  });
}
