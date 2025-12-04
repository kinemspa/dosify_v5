import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Service for calculating schedule occurrences
class ScheduleOccurrenceService {
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
          if (dt.isAfter(now)) return dt;
        }
      }
    }
    
    return null;
  }
  
  /// Checks if a schedule is active on a given day
  static bool _isScheduledOnDay(Schedule schedule, DateTime date, DateTime now) {
    // Check monthly schedule (days of month)
    if (schedule.hasDaysOfMonth) {
      return schedule.daysOfMonth!.contains(date.day);
    }
    
    // Check cyclic schedule (every N days)
    if (schedule.hasCycle && schedule.cycleEveryNDays != null && schedule.cycleEveryNDays! > 0) {
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
    final occurrences = <DateTime>[];
    final times = schedule.timesOfDay ?? [schedule.minutesOfDay];
    
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (_isScheduledOnDay(schedule, current, DateTime.now())) {
        for (final minutes in times) {
          final dt = DateTime(
            current.year,
            current.month,
            current.day,
            minutes ~/ 60,
            minutes % 60,
          );
          if ((dt.isAfter(start) || dt.isAtSameMomentAs(start)) &&
              (dt.isBefore(end) || dt.isAtSameMomentAs(end))) {
            occurrences.add(dt);
          }
        }
      }
      current = current.add(const Duration(days: 1));
    }
    
    return occurrences;
  }
}
