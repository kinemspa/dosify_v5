import 'package:flutter_test/flutter_test.dart';

import 'package:skedux/src/core/notifications/entry_timing_settings.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/entry_log_ids.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:skedux/src/features/schedules/data/schedule_scheduler.dart';

void main() {
  test('EntryLogIds prefers base id over legacy snooze', () {
    final scheduled = DateTime.utc(2026, 1, 1, 12);
    final baseId = EntryLogIds.occurrenceId(scheduleId: 's1', scheduledTime: scheduled);
    final snoozeId = EntryLogIds.legacySnoozeIdFromBase(baseId);

    final base = EntryLog(
      id: baseId,
      scheduleId: 's1',
      scheduleName: 'Sched',
      medicationId: 'm1',
      medicationName: 'Med',
      scheduledTime: scheduled,
      actionTime: scheduled,
      entryValue: 1,
      entryUnit: 'mg',
      action: EntryAction.logged,
    );

    final snooze = EntryLog(
      id: snoozeId,
      scheduleId: 's1',
      scheduleName: 'Sched',
      medicationId: 'm1',
      medicationName: 'Med',
      scheduledTime: scheduled,
      actionTime: scheduled.add(const Duration(minutes: 10)),
      entryValue: 1,
      entryUnit: 'mg',
      action: EntryAction.snoozed,
    );

    final picked = EntryLogIds.pickExistingFromMap(
      {snoozeId: snooze, baseId: base},
      scheduleId: 's1',
      scheduledTime: scheduled,
    );

    expect(picked?.id, equals(baseId));
  });

  test('EntryTimingSettings window respects next occurrence', () {
    EntryTimingSettings.value.value = const EntryTimingConfig(
      missedGracePercent: 50,
      overdueReminderPercent: 50,
      followUpReminderCount: 1,
    );

    // Daily schedule at 00:30 (minutesOfDay) with multiple times per day.
    final schedule = Schedule(
      id: 's1',
      name: 'Entry',
      medicationName: 'Med',
      entryValue: 1,
      entryUnit: 'mg',
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

    final missedAt = EntryTimingSettings.missedAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );

    // With 50% grace, missedAt should be halfway to the next entry.
    final grace = next!.difference(scheduledTime);
    final expected = scheduledTime.add(Duration(seconds: (grace.inSeconds * 0.5).round()));
    expect(missedAt, equals(expected));

    final overdueAt = EntryTimingSettings.overdueReminderAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(overdueAt, isNotNull);
    expect(overdueAt!.isAfter(scheduledTime), isTrue);
    expect(overdueAt.isBefore(missedAt), isTrue);
  });

  test('EntryTimingSettings overdueRemindersAt returns correct count', () {
    // Test with count=0 (off)
    EntryTimingSettings.value.value = const EntryTimingConfig(
      missedGracePercent: 50,
      overdueReminderPercent: 50,
      followUpReminderCount: 0,
    );

    final schedule = Schedule(
      id: 's1',
      name: 'Entry',
      medicationName: 'Med',
      entryValue: 1,
      entryUnit: 'mg',
      minutesOfDay: 30,
      timesOfDay: const [30],
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    );

    final scheduledTime = DateTime(2026, 1, 1, 23, 30);
    var reminders = EntryTimingSettings.overdueRemindersAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(reminders, isEmpty);

    // Test with count=1 (once)
    EntryTimingSettings.value.value = const EntryTimingConfig(
      missedGracePercent: 50,
      overdueReminderPercent: 50,
      followUpReminderCount: 1,
    );
    reminders = EntryTimingSettings.overdueRemindersAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(reminders.length, equals(1));
    expect(reminders[0].isAfter(scheduledTime), isTrue);

    // Test with count=2 (twice)
    EntryTimingSettings.value.value = const EntryTimingConfig(
      missedGracePercent: 50,
      overdueReminderPercent: 50,
      followUpReminderCount: 2,
    );
    reminders = EntryTimingSettings.overdueRemindersAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(reminders.length, equals(2));
    expect(reminders[0].isAfter(scheduledTime), isTrue);
    expect(reminders[1].isAfter(reminders[0]), isTrue);
    
    final missedAt = EntryTimingSettings.missedAt(
      schedule: schedule,
      scheduledTime: scheduledTime,
    );
    expect(reminders[0].isBefore(missedAt), isTrue);
    expect(reminders[1].isBefore(missedAt), isTrue);
  });

  test('ScheduleScheduler entry notification id is stable', () {
    final t = DateTime.utc(2026, 1, 1, 12);
    final a = ScheduleScheduler.entryNotificationIdFor('s1', t);
    final b = ScheduleScheduler.entryNotificationIdFor('s1', t);
    final c = ScheduleScheduler.entryNotificationIdFor('s1', t.add(const Duration(minutes: 1)));
    expect(a, equals(b));
    expect(a, isNot(equals(c)));
  });

  test('ScheduleScheduler overdue notification id is stable and distinct', () {
    final t = DateTime.utc(2026, 1, 1, 12);
    final entry = ScheduleScheduler.entryNotificationIdFor('s1', t);
    final overdueA = ScheduleScheduler.overdueNotificationIdFor('s1', t);
    final overdueB = ScheduleScheduler.overdueNotificationIdFor('s1', t);
    expect(overdueA, equals(overdueB));
    expect(overdueA, isNot(equals(entry)));
  });

  test('ScheduleScheduler group key is stable per local minute', () {
    final dt = DateTime(2026, 1, 2, 3, 4);
    expect(ScheduleScheduler.entryGroupKeyFor(dt), equals('upcoming_entry|20260102|0304'));

    // Same minute should group; different minute should not.
    expect(
      ScheduleScheduler.entryGroupKeyFor(DateTime(2026, 1, 2, 3, 4, 59)),
      equals('upcoming_entry|20260102|0304'),
    );
    expect(
      ScheduleScheduler.entryGroupKeyFor(DateTime(2026, 1, 2, 3, 5)),
      equals('upcoming_entry|20260102|0305'),
    );
  });
}
