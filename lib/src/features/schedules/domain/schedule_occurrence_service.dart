import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Service for calculating schedule occurrences
class ScheduleOccurrenceService {
  static int _lastDayOfMonth(DateTime date) {
    final last = DateTime(date.year, date.month + 1, 0);
    return last.day;
  }

  static bool _isMonthlyScheduledOnDay(Schedule schedule, DateTime date) {
    final days = schedule.daysOfMonth;
    if (days == null || days.isEmpty) return false;

    if (days.contains(date.day)) return true;

    if (schedule.monthlyMissingDayBehavior !=
        MonthlyMissingDayBehavior.lastDay) {
      return false;
    }

    final lastDay = _lastDayOfMonth(date);
    if (date.day != lastDay) return false;

    // If any selected day exceeds this month length (e.g., 31 in a 30-day month),
    // schedule it on the last day.
    return days.any((d) => d > lastDay);
  }

  static bool _isWithinBounds(Schedule schedule, DateTime dt) {
    final startAt = schedule.startAt;
    if (startAt != null && dt.isBefore(startAt)) return false;
    final endAt = schedule.endAt;
    if (endAt != null && dt.isAfter(endAt)) return false;
    return true;
  }

  /// Finds the next occurrence of a schedule after the current time.
  ///
  /// Returns null if no occurrence is found within the next 60 days.
  ///
  /// Supports:
  /// - Daily schedules (every day)
  /// - Weekly schedules (specific days of week)
  /// - Cyclic schedules (every N days)
  /// - Monthly schedules (specific days of month)
  /// - Multiple times per day
  static DateTime? nextOccurrence(Schedule schedule, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final times = schedule.timesOfDay ?? [schedule.minutesOfDay];

    // Look ahead up to 60 days
    for (var d = 0; d < 60; d++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: d));

      final onDay = _isScheduledOnDay(schedule, date, now);

      if (onDay) {
        for (final minutes in times) {
          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            minutes ~/ 60,
            minutes % 60,
          );
          if (dt.isAfter(now) && _isWithinBounds(schedule, dt)) return dt;
        }
      }
    }

    return null;
  }

  /// Checks if a schedule is active on a given day
  static bool _isScheduledOnDay(
    Schedule schedule,
    DateTime date,
    DateTime now,
  ) {
    // Check monthly schedule (days of month)
    if (schedule.hasDaysOfMonth) {
      return _isMonthlyScheduledOnDay(schedule, date);
    }

    // Check cyclic schedule (every N days)
    if (schedule.hasCycle &&
        schedule.cycleEveryNDays != null &&
        schedule.cycleEveryNDays! > 0) {
      final anchor = schedule.cycleAnchorDate ?? now;
      final anchorDate = DateTime(anchor.year, anchor.month, anchor.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      final diff = targetDate.difference(anchorDate).inDays;
      return diff >= 0 && diff % schedule.cycleEveryNDays! == 0;
    }

    // Default: check days of week
    return schedule.daysOfWeek.contains(date.weekday);
  }

  /// Finds all occurrences of a schedule within a date range
  static List<DateTime> occurrencesInRange(
    Schedule schedule,
    DateTime start,
    DateTime end,
  ) {
    return occurrencesInRangeWithReferenceNow(
      schedule,
      start,
      end,
      referenceNow: DateTime.now(),
    );
  }

  /// Like [occurrencesInRange], but allows controlling the reference "now"
  /// used by cyclic schedules when no anchor date exists.
  static List<DateTime> occurrencesInRangeWithReferenceNow(
    Schedule schedule,
    DateTime start,
    DateTime end, {
    required DateTime referenceNow,
  }) {
    final occurrences = <DateTime>[];
    final times = schedule.timesOfDay ?? [schedule.minutesOfDay];

    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (_isScheduledOnDay(schedule, current, referenceNow)) {
        for (final minutes in times) {
          final dt = DateTime(
            current.year,
            current.month,
            current.day,
            minutes ~/ 60,
            minutes % 60,
          );
          if ((dt.isAfter(start) || dt.isAtSameMomentAs(start)) &&
              (dt.isBefore(end) || dt.isAtSameMomentAs(end)) &&
              _isWithinBounds(schedule, dt)) {
            occurrences.add(dt);
          }
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return occurrences;
  }

  /// Returns the 1-based occurrence number for a given scheduled dose time.
  ///
  /// The numbering starts at 1 per schedule, based on all scheduled occurrences
  /// from the schedule's effective start to the provided [occurrence]
  /// (inclusive).
  ///
  /// Returns null if the [occurrence] is not a valid occurrence for the
  /// schedule.
  static int? occurrenceNumber(Schedule schedule, DateTime occurrence) {
    final start = schedule.startAt ?? schedule.createdAt;
    if (occurrence.isBefore(start)) return null;

    final referenceNow = schedule.cycleAnchorDate ?? start;
    final occurrences = occurrencesInRangeWithReferenceNow(
      schedule,
      start,
      occurrence,
      referenceNow: referenceNow,
    );

    final idx = occurrences.indexWhere((dt) => dt == occurrence);
    if (idx < 0) return null;
    return idx + 1;
  }
}
