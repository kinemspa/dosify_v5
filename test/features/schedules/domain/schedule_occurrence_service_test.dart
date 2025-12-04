import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';

void main() {
  group('ScheduleOccurrenceService', () {
    group('nextOccurrence', () {
      test('returns next occurrence for daily schedule', () {
        final now = DateTime(2024, 1, 15, 10, 0); // Monday 10:00 AM
        final schedule = Schedule(
          id: '1',
          name: 'Daily Med',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 14 * 60, // 2:00 PM
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Every day
        );

        final next = ScheduleOccurrenceService.nextOccurrence(
          schedule,
          from: now,
        );

        expect(next, isNotNull);
        expect(next!.year, 2024);
        expect(next.month, 1);
        expect(next.day, 15); // Same day
        expect(next.hour, 14); // 2:00 PM
        expect(next.minute, 0);
      });

      test('returns next day occurrence when time has passed', () {
        final now = DateTime(2024, 1, 15, 15, 0); // Monday 3:00 PM
        final schedule = Schedule(
          id: '1',
          name: 'Daily Med',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 14 * 60, // 2:00 PM
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Every day
        );

        final next = ScheduleOccurrenceService.nextOccurrence(
          schedule,
          from: now,
        );

        expect(next, isNotNull);
        expect(next!.day, 16); // Next day (Tuesday)
        expect(next.hour, 14);
      });

      test('returns correct occurrence for weekly schedule', () {
        final now = DateTime(2024, 1, 15, 10, 0); // Monday 10:00 AM
        final schedule = Schedule(
          id: '1',
          name: 'Weekly Med',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 9 * 60, // 9:00 AM
          daysOfWeek: [3, 5], // Wednesday and Friday only
        );

        final next = ScheduleOccurrenceService.nextOccurrence(
          schedule,
          from: now,
        );

        expect(next, isNotNull);
        expect(next!.weekday, 3); // Wednesday
        expect(next.day, 17); // Jan 17 is Wednesday
        expect(next.hour, 9);
      });

      test('handles multiple times per day', () {
        final now = DateTime(2024, 1, 15, 10, 0); // Monday 10:00 AM
        final schedule = Schedule(
          id: '1',
          name: 'Multi-time Med',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 9 * 60, // Legacy field
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          timesOfDay: [9 * 60, 14 * 60, 20 * 60], // 9 AM, 2 PM, 8 PM
        );

        final next = ScheduleOccurrenceService.nextOccurrence(
          schedule,
          from: now,
        );

        expect(next, isNotNull);
        expect(next!.day, 15); // Same day
        expect(next.hour, 14); // Next time is 2:00 PM
      });

      test('returns correct occurrence for cyclic schedule', () {
        final anchor = DateTime(2024, 1, 1); // Start on Jan 1
        final now = DateTime(2024, 1, 15, 10, 0); // Monday Jan 15, 10:00 AM
        final schedule = Schedule(
          id: '1',
          name: 'Every 3 Days',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 9 * 60, // 9:00 AM
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Ignored for cyclic
          cycleEveryNDays: 3,
          cycleAnchorDate: anchor,
        );

        final next = ScheduleOccurrenceService.nextOccurrence(
          schedule,
          from: now,
        );

        expect(next, isNotNull);
        // Jan 1, 4, 7, 10, 13, 16, 19...
        // From Jan 15, next is Jan 16
        expect(next!.day, 16);
        expect(next.hour, 9);
      });

      test('returns correct occurrence for monthly schedule', () {
        final now = DateTime(2024, 1, 10, 10, 0); // Jan 10, 10:00 AM
        final schedule = Schedule(
          id: '1',
          name: 'Monthly Med',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 9 * 60, // 9:00 AM
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Ignored for monthly
          daysOfMonth: [1, 15], // 1st and 15th of each month
        );

        final next = ScheduleOccurrenceService.nextOccurrence(
          schedule,
          from: now,
        );

        expect(next, isNotNull);
        expect(next!.day, 15); // Next is Jan 15
        expect(next.month, 1);
        expect(next.hour, 9);
      });

      test('returns null when no occurrence within 60 days', () {
        final now = DateTime(2024, 1, 15, 10, 0);
        final schedule = Schedule(
          id: '1',
          name: 'Far Future',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 9 * 60,
          daysOfWeek: [], // No days scheduled
        );

        final next = ScheduleOccurrenceService.nextOccurrence(
          schedule,
          from: now,
        );

        expect(next, isNull);
      });
    });

    group('occurrencesInRange', () {
      test('returns all occurrences in date range for daily schedule', () {
        final schedule = Schedule(
          id: '1',
          name: 'Daily Med',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 9 * 60, // 9:00 AM
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        );

        final start = DateTime(2024, 1, 15, 0, 0);
        final end = DateTime(2024, 1, 17, 23, 59);

        final occurrences = ScheduleOccurrenceService.occurrencesInRange(
          schedule,
          start,
          end,
        );

        expect(occurrences.length, 3); // Jan 15, 16, 17
        expect(occurrences[0].day, 15);
        expect(occurrences[1].day, 16);
        expect(occurrences[2].day, 17);
      });

      test('returns multiple times per day in range', () {
        final schedule = Schedule(
          id: '1',
          name: 'Multi-time Med',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 9 * 60,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          timesOfDay: [9 * 60, 14 * 60], // 9 AM and 2 PM
        );

        final start = DateTime(2024, 1, 15, 0, 0);
        final end = DateTime(2024, 1, 16, 23, 59);

        final occurrences = ScheduleOccurrenceService.occurrencesInRange(
          schedule,
          start,
          end,
        );

        expect(occurrences.length, 4); // 2 days × 2 times = 4
      });

      test('respects weekly schedule in range', () {
        final schedule = Schedule(
          id: '1',
          name: 'Weekly Med',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 9 * 60,
          daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
        );

        final start = DateTime(2024, 1, 15, 0, 0); // Monday
        final end = DateTime(2024, 1, 21, 23, 59); // Sunday

        final occurrences = ScheduleOccurrenceService.occurrencesInRange(
          schedule,
          start,
          end,
        );

        // Jan 15 (Mon), 17 (Wed), 19 (Fri)
        expect(occurrences.length, 3);
        expect(occurrences[0].weekday, 1);
        expect(occurrences[1].weekday, 3);
        expect(occurrences[2].weekday, 5);
      });
    });
  });
}
