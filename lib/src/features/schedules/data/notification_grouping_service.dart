// Package imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Strategy for how notifications should be displayed
enum NotificationStrategy {
  /// One notification per schedule
  individual,

  /// Grouped notification with expandable individual actions
  groupedExpandable,

  /// Grouped summary notification with "Open app to view all"
  groupedSummary,
}

/// User preference for notification grouping
enum GroupingPreference {
  /// Always show individual notifications
  alwaysSeparate,

  /// Always group notifications at same time
  alwaysGroup,

  /// Smart grouping based on count (default)
  smart,
}

/// Represents a group of schedules that have doses at the same time
class ScheduleGroup {
  final DateTime scheduledTime;
  final List<Schedule> schedules;
  final NotificationStrategy strategy;

  const ScheduleGroup({
    required this.scheduledTime,
    required this.schedules,
    required this.strategy,
  });

  /// Generates a unique group ID for this time slot
  String get groupId {
    final timestamp =
        scheduledTime.millisecondsSinceEpoch ~/ 60000; // minute precision
    return 'group_$timestamp';
  }

  /// Gets a unique notification ID for this group
  int get notificationId {
    // Use a stable hash of the group ID to get consistent notification IDs
    return _stableHash32(groupId) & 0x7FFFFFFF;
  }

  static int _stableHash32(String s) {
    const fnvOffset = 0x811C9DC5;
    const fnvPrime = 0x01000193;
    var hash = fnvOffset;
    for (final codeUnit in s.codeUnits) {
      hash ^= codeUnit & 0xFF;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}

/// Service for grouping notifications by time and determining display strategy
class NotificationGroupingService {
  /// Time window for grouping (schedules within this window are grouped)
  static const Duration groupingWindow = Duration(minutes: 1);

  /// Groups schedules by their scheduled time
  ///
  /// Returns a map of rounded times to lists of schedules
  static Map<DateTime, List<Schedule>> groupByTime(
    List<Schedule> schedules,
    DateTime startDate,
    DateTime endDate,
  ) {
    final groups = <DateTime, List<Schedule>>{};

    for (final schedule in schedules) {
      if (!schedule.active) continue;

      // Get all dose times for this schedule in the date range
      final doseTimes = _calculateDoseTimes(schedule, startDate, endDate);

      for (final doseTime in doseTimes) {
        final roundedTime = _roundToMinute(doseTime);
        groups.putIfAbsent(roundedTime, () => []).add(schedule);
      }
    }

    return groups;
  }

  /// Creates schedule groups with appropriate display strategies
  static List<ScheduleGroup> createGroups(
    Map<DateTime, List<Schedule>> timeGroups,
    GroupingPreference preference,
  ) {
    final groups = <ScheduleGroup>[];

    for (final entry in timeGroups.entries) {
      final time = entry.key;
      final schedules = entry.value;

      // Determine strategy based on count and user preference
      final strategy = _getStrategy(schedules.length, preference);

      groups.add(
        ScheduleGroup(
          scheduledTime: time,
          schedules: schedules,
          strategy: strategy,
        ),
      );
    }

    return groups;
  }

  /// Determines the notification strategy based on schedule count and user preference
  static NotificationStrategy _getStrategy(
    int count,
    GroupingPreference preference,
  ) {
    if (preference == GroupingPreference.alwaysSeparate) {
      return NotificationStrategy.individual;
    }

    if (preference == GroupingPreference.alwaysGroup) {
      if (count == 1) return NotificationStrategy.individual;
      if (count <= 3) return NotificationStrategy.groupedExpandable;
      return NotificationStrategy.groupedSummary;
    }

    // Smart grouping (default)
    if (count == 1) {
      return NotificationStrategy.individual;
    } else if (count <= 3) {
      return NotificationStrategy.groupedExpandable;
    } else {
      return NotificationStrategy.groupedSummary;
    }
  }

  /// Rounds a DateTime to the nearest minute
  static DateTime _roundToMinute(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  /// Calculates all dose times for a schedule within a date range
  static List<DateTime> _calculateDoseTimes(
    Schedule schedule,
    DateTime startDate,
    DateTime endDate,
  ) {
    final doseTimes = <DateTime>[];
    final times = schedule.timesOfDay ?? [schedule.minutesOfDay];

    if (schedule.hasCycle) {
      // Cycle-based schedule
      final cycleLength = schedule.cycleEveryNDays ?? 1;
      final anchorDate = schedule.cycleAnchorDate ?? startDate;

      var currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final daysSinceAnchor = currentDate.difference(anchorDate).inDays;

        if (daysSinceAnchor >= 0 && daysSinceAnchor % cycleLength == 0) {
          // This is a dose day
          for (final minutesOfDay in times) {
            final hour = minutesOfDay ~/ 60;
            final minute = minutesOfDay % 60;
            final doseTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              hour,
              minute,
            );

            if (doseTime.isAfter(startDate) &&
                (doseTime.isBefore(endDate) ||
                    doseTime.isAtSameMomentAs(endDate))) {
              doseTimes.add(doseTime);
            }
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }
    } else {
      // Day of week schedule
      var currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final weekday = currentDate.weekday;

        if (schedule.daysOfWeek.contains(weekday)) {
          // This is a dose day
          for (final minutesOfDay in times) {
            final hour = minutesOfDay ~/ 60;
            final minute = minutesOfDay % 60;
            final doseTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              hour,
              minute,
            );

            if (doseTime.isAfter(startDate) &&
                (doseTime.isBefore(endDate) ||
                    doseTime.isAtSameMomentAs(endDate))) {
              doseTimes.add(doseTime);
            }
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    return doseTimes;
  }

  /// Gets the notification title for a group
  static String getGroupTitle(ScheduleGroup group) {
    final count = group.schedules.length;
    final time = _formatTime(group.scheduledTime);

    if (count == 1) {
      return group.schedules.first.name;
    } else {
      return '$count Medications Due - $time';
    }
  }

  /// Gets the notification body for a group
  static String getGroupBody(ScheduleGroup group) {
    if (group.strategy == NotificationStrategy.individual) {
      final schedule = group.schedules.first;
      return _getDoseDescription(schedule);
    }

    if (group.strategy == NotificationStrategy.groupedSummary) {
      return 'Tap to view all medications';
    }

    // Grouped expandable - list all schedules
    return group.schedules
        .map((s) => '• ${s.name}${_getDoseDescription(s, short: true)}')
        .join('\n');
  }

  /// Gets a dose description for a schedule
  static String _getDoseDescription(Schedule schedule, {bool short = false}) {
    final value = schedule.doseValue;
    final unit = schedule.doseUnit;

    if (short) {
      return ' ($value $unit)';
    }

    return 'Take $value $unit';
  }

  /// Formats a time for display
  static String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Logs grouping information for debugging
  static void logGroups(List<ScheduleGroup> groups) {
    debugPrint(
      '[NotificationGroupingService] Created ${groups.length} groups:',
    );
    for (final group in groups) {
      debugPrint(
        '  ${group.scheduledTime}: ${group.schedules.length} schedules, '
        'strategy: ${group.strategy}',
      );
    }
  }
}
