import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';

@immutable
class DoseTimingConfig {
  const DoseTimingConfig({
    required this.missedGracePercent,
    required this.overdueReminderPercent,
    required this.followUpReminderCount,
  });

  /// Percentage (0..100) of the time until the next scheduled dose
  /// after which a dose is considered "missed".
  ///
  /// Example: if the next dose is in 8 hours and this is 50, the dose becomes
  /// missed after 4 hours.
  final int missedGracePercent;

  /// Percentage (0..100) of the time before the dose is considered missed
  /// at which an "overdue" reminder should fire.
  ///
  /// Example: with missedGracePercent=50 and overdueReminderPercent=50,
  /// reminder fires at 25% of the interval to the next dose.
  ///
  /// Set to 0 to disable.
  final int overdueReminderPercent;

  /// Number of follow-up reminders to send after the scheduled time.
  ///
  /// 0 = Off (no reminders)
  /// 1 = Once
  /// 2 = Twice
  /// etc.
  final int followUpReminderCount;

  DoseTimingConfig copyWith({
    int? missedGracePercent,
    int? overdueReminderPercent,
    int? followUpReminderCount,
  }) {
    return DoseTimingConfig(
      missedGracePercent: missedGracePercent ?? this.missedGracePercent,
      overdueReminderPercent:
          overdueReminderPercent ?? this.overdueReminderPercent,
      followUpReminderCount:
          followUpReminderCount ?? this.followUpReminderCount,
    );
  }
}

class DoseTimingSettings {
  const DoseTimingSettings._();

  static const String _prefsKeyMissedGracePercent =
      'dose_timing.missed_grace_percent_v1';
  static const String _prefsKeyOverdueReminderPercent =
      'dose_timing.overdue_reminder_percent_v1';
  static const String _prefsKeyFollowUpReminderCount =
      'dose_timing.follow_up_reminder_count_v1';

  static const int defaultMissedGracePercent = 50;
  static const int defaultOverdueReminderPercent = 50;
  static const int defaultFollowUpReminderCount = 1;

  /// Used when the schedule cannot be resolved or has no upcoming occurrence.
  static const Duration fallbackGraceWindow = Duration(minutes: 60);

  static final ValueNotifier<DoseTimingConfig> value = ValueNotifier(
    const DoseTimingConfig(
      missedGracePercent: defaultMissedGracePercent,
      overdueReminderPercent: defaultOverdueReminderPercent,
      followUpReminderCount: defaultFollowUpReminderCount,
    ),
  );

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final missed =
          prefs.getInt(_prefsKeyMissedGracePercent) ?? defaultMissedGracePercent;
      final overdue = prefs.getInt(_prefsKeyOverdueReminderPercent) ??
          defaultOverdueReminderPercent;
      final followUpCount = prefs.getInt(_prefsKeyFollowUpReminderCount) ??
          defaultFollowUpReminderCount;
      value.value = value.value.copyWith(
        missedGracePercent: _clampPercent(missed),
        overdueReminderPercent: _clampPercent(overdue),
        followUpReminderCount: followUpCount.clamp(0, 10),
      );
    } catch (_) {
      // Best-effort; keep defaults.
    }
  }

  static int _clampPercent(int raw) => raw.clamp(0, 100);

  static Future<void> setMissedGracePercent(int percent) async {
    final next = _clampPercent(percent);
    value.value = value.value.copyWith(missedGracePercent: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyMissedGracePercent, next);
    } catch (_) {
      // Best-effort.
    }
  }

  static Future<void> setOverdueReminderPercent(int percent) async {
    final next = _clampPercent(percent);
    value.value = value.value.copyWith(overdueReminderPercent: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyOverdueReminderPercent, next);
    } catch (_) {
      // Best-effort.
    }
  }

  static Future<void> setFollowUpReminderCount(int count) async {
    final next = count.clamp(0, 10);
    value.value = value.value.copyWith(followUpReminderCount: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyFollowUpReminderCount, next);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Returns the moment at which a dose should be considered "missed".
  static DateTime missedAt({
    required Schedule schedule,
    required DateTime scheduledTime,
  }) {
    final next = ScheduleOccurrenceService.nextOccurrence(
      schedule,
      from: scheduledTime.add(const Duration(seconds: 1)),
    );

    final graceWindow = (next != null && next.isAfter(scheduledTime))
        ? next.difference(scheduledTime)
        : fallbackGraceWindow;

    final pct = value.value.missedGracePercent;

    // pct=0 => immediately missed; pct=100 => right at the next dose.
    final seconds = (graceWindow.inSeconds * pct / 100).round();
    return scheduledTime.add(Duration(seconds: seconds));
  }

  /// Computes the reminder time for an "overdue" notification.
  ///
  /// Returns null when disabled or when a reminder would be nonsensical.
  static DateTime? overdueReminderAt({
    required Schedule schedule,
    required DateTime scheduledTime,
  }) {
    final overduePct = value.value.overdueReminderPercent;
    if (overduePct <= 0) return null;

    final missed = missedAt(schedule: schedule, scheduledTime: scheduledTime);
    if (!missed.isAfter(scheduledTime)) return null;

    final window = missed.difference(scheduledTime);
    final seconds = (window.inSeconds * overduePct / 100).round();
    final reminder = scheduledTime.add(Duration(seconds: seconds));

    if (!reminder.isAfter(scheduledTime)) return null;
    if (!reminder.isBefore(missed)) return null;

    return reminder;
  }

  /// Computes multiple follow-up reminder times based on the configured count.
  ///
  /// Returns a list of reminder times evenly distributed within the grace window.
  /// Returns an empty list when disabled or when reminders would be nonsensical.
  static List<DateTime> followUpReminderTimes({
    required Schedule schedule,
    required DateTime scheduledTime,
  }) {
    final count = value.value.followUpReminderCount;
    if (count <= 0) return [];

    final overduePct = value.value.overdueReminderPercent;
    if (overduePct <= 0) return [];

    final missed = missedAt(schedule: schedule, scheduledTime: scheduledTime);
    if (!missed.isAfter(scheduledTime)) return [];

    final window = missed.difference(scheduledTime);
    final reminders = <DateTime>[];

    // Distribute reminders evenly within the grace window
    for (var i = 1; i <= count; i++) {
      // Calculate the position for this reminder
      // First reminder at overdueReminderPercent, subsequent ones spaced evenly
      final pct = (overduePct * i / count).round();
      final seconds = (window.inSeconds * pct / 100).round();
      final reminder = scheduledTime.add(Duration(seconds: seconds));

      if (!reminder.isAfter(scheduledTime)) continue;
      if (!reminder.isBefore(missed)) continue;

      reminders.add(reminder);
    }

    return reminders;
  }

  /// Best-effort helper for status computation when you only have a scheduleId.
  static DateTime missedAtForScheduleId({
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    try {
      final box = Hive.box<Schedule>('schedules');
      final schedule = box.get(scheduleId);
      if (schedule == null) return scheduledTime.add(fallbackGraceWindow);
      return missedAt(schedule: schedule, scheduledTime: scheduledTime);
    } catch (_) {
      return scheduledTime.add(fallbackGraceWindow);
    }
  }
}
