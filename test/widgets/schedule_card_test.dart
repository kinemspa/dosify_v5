import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_card.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Initialize a temp Hive directory for tests
    final dir = Directory.systemTemp.createTempSync('dosifi_test_hive');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(DoseLogAdapter());
    if (!Hive.isAdapterRegistered(42))
      Hive.registerAdapter(DoseActionAdapter());
    await Hive.openBox<DoseLog>('dose_logs');
  });

  tearDown(() async {
    await Hive.box<DoseLog>('dose_logs').clear();
    await Hive.box<DoseLog>('dose_logs').close();
    // Clean test overrides
    NotificationService.scheduleAtAlarmClockOverride = null;
    NotificationService.cancelOverride = null;
  });

  testWidgets('snooze creates dose log and schedules one-off snooze', (
    WidgetTester tester,
  ) async {
    final scheduledCalls = <Map<String, dynamic>>[];
    NotificationService.scheduleAtAlarmClockOverride =
        (
          int id,
          DateTime when, {
          required String title,
          required String body,
          String channelId = 'upcoming_dose',
        }) async {
          scheduledCalls.add({
            'id': id,
            'when': when,
            'title': title,
            'body': body,
          });
        };

    // Prepare a schedule that occurs 1 minute from now
    final now = DateTime.now().toLocal();
    final scheduledTime = now.add(const Duration(minutes: 1));
    final minutes = scheduledTime.hour * 60 + scheduledTime.minute;
    final schedule = Schedule(
      id: 's1',
      name: 'Test Schedule',
      medicationName: 'TestMed',
      doseValue: 1.0,
      doseUnit: 'tab',
      minutesOfDay: minutes,
      daysOfWeek: [scheduledTime.weekday],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleCard(s: schedule, dense: true, useGradient: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open popup menu for snooze
    final menuFinder = find.byIcon(Icons.more_vert);
    expect(menuFinder, findsOneWidget);
    await tester.tap(menuFinder);
    await tester.pumpAndSettle();

    final snoozeItem = find.text('Snooze');
    expect(snoozeItem, findsOneWidget);
    await tester.tap(snoozeItem);
    await tester.pumpAndSettle();
    // Allow the async snooze handler to finish the DB write and scheduling.
    await tester.pump(const Duration(milliseconds: 500));

    // Verify DoseLog created
    final box = Hive.box<DoseLog>('dose_logs');
    expect(box.length, 1);
    final log = box.values.first;
    expect(log.action, DoseAction.snoozed);

    // Verify notification scheduling occurred via override
    expect(scheduledCalls.length, 1);
    final call = scheduledCalls.first;
    expect(call['title'], equals(schedule.name));
    expect(call['body'], contains(schedule.medicationName));
  });

  testWidgets('skip creates dose log and cancels scheduled notification', (
    WidgetTester tester,
  ) async {
    final canceled = <int>[];
    NotificationService.cancelOverride = (int id) async {
      canceled.add(id);
    };

    // Prepare a schedule that occurs 1 minute from now
    final now = DateTime.now().toLocal();
    final scheduledTime = now.add(const Duration(minutes: 1));
    final minutes = scheduledTime.hour * 60 + scheduledTime.minute;
    final schedule = Schedule(
      id: 's2',
      name: 'Test Schedule 2',
      medicationName: 'TestMed',
      doseValue: 2.0,
      doseUnit: 'tab',
      minutesOfDay: minutes,
      daysOfWeek: [scheduledTime.weekday],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleCard(s: schedule, dense: true, useGradient: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open popup menu and select Skip
    final menuFinder = find.byIcon(Icons.more_vert);
    expect(menuFinder, findsOneWidget);
    await tester.tap(menuFinder);
    await tester.pumpAndSettle();

    final skipItem = find.text('Skip');
    expect(skipItem, findsOneWidget);
    await tester.tap(skipItem);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify DoseLog created
    final box = Hive.box<DoseLog>('dose_logs');
    expect(box.length, 1);
    final log = box.values.first;
    expect(log.action, DoseAction.skipped);

    // Verify cancel called
    expect(canceled.length, greaterThanOrEqualTo(1));
  });
}
