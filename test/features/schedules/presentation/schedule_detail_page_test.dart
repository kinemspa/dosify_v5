import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_detail_page.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive with a temporary directory for better test isolation
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    
    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MedicationAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScheduleAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DoseLogAdapter());
    }
  });

  setUp(() async {
    // Clean up boxes before each test
    if (Hive.isBoxOpen('medications')) {
      await Hive.box<Medication>('medications').clear();
    } else {
      await Hive.openBox<Medication>('medications');
    }
    
    if (Hive.isBoxOpen('schedules')) {
      await Hive.box<Schedule>('schedules').clear();
    } else {
      await Hive.openBox<Schedule>('schedules');
    }
    
    if (Hive.isBoxOpen('dose_logs')) {
      await Hive.box<DoseLog>('dose_logs').clear();
    } else {
      await Hive.openBox<DoseLog>('dose_logs');
    }
  });

  tearDown(() async {
    // Close boxes after each test for better isolation
    if (Hive.isBoxOpen('medications')) {
      await Hive.box<Medication>('medications').close();
    }
    if (Hive.isBoxOpen('schedules')) {
      await Hive.box<Schedule>('schedules').close();
    }
    if (Hive.isBoxOpen('dose_logs')) {
      await Hive.box<DoseLog>('dose_logs').close();
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('ScheduleDetailPage initializes without crashing', (
    WidgetTester tester,
  ) async {
    // Create a test schedule
    final schedule = Schedule(
      id: 'test-schedule-1',
      name: 'Test Schedule',
      medicationName: 'Test Medication',
      doseValue: 1.0,
      doseUnit: 'tablet',
      minutesOfDay: 480, // 8:00 AM
      daysOfWeek: const [1, 2, 3, 4, 5],
    );

    final scheduleBox = Hive.box<Schedule>('schedules');
    await scheduleBox.put(schedule.id, schedule);

    // Verify the page builds without throwing
    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleDetailPage(scheduleId: schedule.id),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify no errors were thrown during initialization
    // The page should at least start building
    expect(find.byType(ScheduleDetailPage), findsOneWidget);
  });

  testWidgets('ScheduleDetailPage handles missing schedule gracefully', (
    WidgetTester tester,
  ) async {
    // Try to load a page with a non-existent schedule ID
    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleDetailPage(scheduleId: 'non-existent-id'),
      ),
    );

    // Initial frame
    await tester.pump();

    // The page should build even if the schedule doesn't exist
    expect(find.byType(ScheduleDetailPage), findsOneWidget);
  });
}
