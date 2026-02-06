import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/notifications/dose_timing_settings.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log_ids.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';

void main() {
  test('DoseLogIds prefers base id over legacy snooze', () {
    final scheduled = DateTime.utc(2026, 1, 1, 12);
    final baseId = DoseLogIds.occurrenceId(scheduleId: 's1', scheduledTime: scheduled);
    final snoozeId = DoseLogIds.legacySnoozeIdFromBase(baseId);

    final base = DoseLog(
      id: baseId,
      scheduleId: 's1',
      scheduleName: 'Sched',
      medicationId: 'm1',
      medicationName: 'Med',
      scheduledTime: scheduled,
      actionTime: scheduled,
      doseValue: 1,
      doseUnit: 'mg',
      action: DoseAction.taken,
    );

    final snooze = DoseLog(
      id: snoozeId,
      scheduleId: 's1',
      scheduleName: 'Sched',
      medicationId: 'm1',
      medicationName: 'Med',
      scheduledTime: scheduled,
      actionTime: scheduled.add(const Duration(minutes: 10)),
      doseValue: 1,
      doseUnit: 'mg',
      action: DoseAction.snoozed,
    );

    final picked = DoseLogIds.pickExistingFromMap(
      {snoozeId: snooze, baseId: base},
      scheduleId: 's1',
      scheduledTime: scheduled,
    );

    expect(picked?.id, equals(baseId));
  });

  test('DoseTimingSettings window respects next occurrence', () {
    DoseTimingSettings.value.value = const DoseTimingConfig(
      missedGracePercent: 50,
      overdueReminderPercent: 50,
      followUpReminderCount: 1,
    );

    // Daily schedule at 00:30 (minutesOfDay) with multiple times per day.
    final schedule = Schedule(
      id: 's1',
      name: 'Dose',
      medicationName: 'Med',
      doseValue: 1,
      doseUnit: 'mg',
      minutesOfDay: 30,
      timesOfDay: const [30],
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    );

    final scheduledTime = DateTime(2026, 1, 1, 23, 30);
    final next = ScheduleOccurrenceService.nextOccurrence(
      schedule,
      from: scheduledTime.add(const Duration(seconds: 1)),
    );
    expect(next, isNotNull);

    final missedAt = DoseTimingSettings.missedAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );

    // With 50% grace, missedAt should be halfway to the next dose.
    final grace = next!.difference(scheduledTime);
    final expected = scheduledTime.add(Duration(seconds: (grace.inSeconds * 0.5).round()));
    expect(missedAt, equals(expected));

    final overdueAt = DoseTimingSettings.overdueReminderAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(overdueAt, isNotNull);
    expect(overdueAt!.isAfter(scheduledTime), isTrue);
    expect(overdueAt.isBefore(missedAt), isTrue);
  });

  test('DoseTimingSettings overdueRemindersAt returns correct count', () {
    // Test with count=0 (off)
    DoseTimingSettings.value.value = const DoseTimingConfig(
      missedGracePercent: 50,
      overdueReminderPercent: 50,
      followUpReminderCount: 0,
    );

    final schedule = Schedule(
      id: 's1',
      name: 'Dose',
      medicationName: 'Med',
      doseValue: 1,
      doseUnit: 'mg',
      minutesOfDay: 30,
      timesOfDay: const [30],
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    );

    final scheduledTime = DateTime(2026, 1, 1, 23, 30);
    var reminders = DoseTimingSettings.overdueRemindersAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(reminders, isEmpty);

    // Test with count=1 (once)
    DoseTimingSettings.value.value = const DoseTimingConfig(
      missedGracePercent: 50,
      overdueReminderPercent: 50,
      followUpReminderCount: 1,
    );
    reminders = DoseTimingSettings.overdueRemindersAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(reminders.length, equals(1));
    expect(reminders[0].isAfter(scheduledTime), isTrue);

    // Test with count=2 (twice)
    DoseTimingSettings.value.value = const DoseTimingConfig(
      missedGracePercent: 50,
      overdueReminderPercent: 50,
      followUpReminderCount: 2,
    );
    reminders = DoseTimingSettings.overdueRemindersAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(reminders.length, equals(2));
    expect(reminders[0].isAfter(scheduledTime), isTrue);
    expect(reminders[1].isAfter(reminders[0]), isTrue);
    
    final missedAt = DoseTimingSettings.missedAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(reminders[0].isBefore(missedAt), isTrue);
    expect(reminders[1].isBefore(missedAt), isTrue);
  });

  test('ScheduleScheduler dose notification id is stable', () {
    final t = DateTime.utc(2026, 1, 1, 12);
    final a = ScheduleScheduler.doseNotificationIdFor('s1', t);
    final b = ScheduleScheduler.doseNotificationIdFor('s1', t);
    final c = ScheduleScheduler.doseNotificationIdFor('s1', t.add(const Duration(minutes: 1)));
    expect(a, equals(b));
    expect(a, isNot(equals(c)));
  });

  test('ScheduleScheduler overdue notification id is stable and distinct', () {
    final t = DateTime.utc(2026, 1, 1, 12);
    final dose = ScheduleScheduler.doseNotificationIdFor('s1', t);
    final overdueA = ScheduleScheduler.overdueNotificationIdFor('s1', t);
    final overdueB = ScheduleScheduler.overdueNotificationIdFor('s1', t);
    expect(overdueA, equals(overdueB));
    expect(overdueA, isNot(equals(dose)));
  });

  test('ScheduleScheduler group key is stable per local minute', () {
    final dt = DateTime(2026, 1, 2, 3, 4);
    expect(ScheduleScheduler.doseGroupKeyFor(dt), equals('upcoming_dose|20260102|0304'));

    // Same minute should group; different minute should not.
    expect(
      ScheduleScheduler.doseGroupKeyFor(DateTime(2026, 1, 2, 3, 4, 59)),
      equals('upcoming_dose|20260102|0304'),
    );
    expect(
      ScheduleScheduler.doseGroupKeyFor(DateTime(2026, 1, 2, 3, 5)),
      equals('upcoming_dose|20260102|0305'),
    );
  });
}
