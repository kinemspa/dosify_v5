// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Service for calculating entry occurrences for calendar views
///
/// This service computes all scheduled entry times for a given date range
/// and matches them with existing entry logs to determine status.
class EntryCalculationService {
  static const int _millisPerMinute = 60 * 1000;

  static int _lastDayOfMonth(DateTime date) {
    final last = DateTime(date.year, date.month + 1, 0);
    return last.day;
  }

  static int _minuteKey(DateTime dt) => dt.millisecondsSinceEpoch ~/ _millisPerMinute;

  static bool _isMonthlyEntryDay(Schedule schedule, DateTime date) {
    final days = schedule.daysOfMonth;
    if (days == null || days.isEmpty) return false;

    if (days.contains(date.day)) return true;

    if (schedule.monthlyMissingDayBehavior !=
        MonthlyMissingDayBehavior.lastDay) {
      return false;
    }

    final lastDay = _lastDayOfMonth(date);
    if (date.day != lastDay) return false;

    return days.any((d) => d > lastDay);
  }

  /// Calculates all entry times for active schedules in a date range
  ///
  /// Returns a list of [CalculatedEntry] objects sorted by scheduled time.
  /// Each entry includes its status based on whether it was logged.
  static Future<List<CalculatedEntry>> calculateEntries({
    required DateTime startDate,
    required DateTime endDate,
    String? scheduleId,
    String? medicationId,
    bool includeInactive = false,
  }) async {
    final schedules = await _getSchedules(scheduleId, medicationId);
    final scheduleIds = schedules.map((s) => s.id).toSet();
    final entryLogs = await _getEntryLogs(
      startDate,
      endDate,
      scheduleIds: scheduleIds,
    );

    final logIndex = _indexLogsByScheduleMinute(entryLogs);

    final entries = <CalculatedEntry>[];

    for (final schedule in schedules) {
      // Let paused-until schedules through; only hard-skip fully disabled ones.
      if (!includeInactive && schedule.isDisabled) continue;

      final scheduleEntries = _calculateScheduleEntries(
        schedule,
        startDate,
        endDate,
      );

      // Match with existing logs
      for (final entry in scheduleEntries) {
        final log = _findMatchingLogIndexed(entry, logIndex);
        entries.add(entry.copyWith(existingLog: log));
      }
    }

    // Sort by scheduled time
    entries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    debugPrint(
      '[EntryCalculationService] Calculated ${entries.length} entries for ${startDate.toLocal()} to ${endDate.toLocal()}',
    );

    return entries;
  }

  /// Gets schedules from Hive based on filters
  static Future<List<Schedule>> _getSchedules(
    String? scheduleId,
    String? medicationId,
  ) async {
    final box = Hive.box<Schedule>('schedules');

    if (scheduleId != null) {
      final schedule = box.get(scheduleId);
      return schedule != null ? [schedule] : [];
    }

    if (medicationId != null) {
      return box.values
          .where((s) => s.medicationId == medicationId)
          .toList(growable: false);
    }

    return box.values.toList(growable: false);
  }

  /// Gets entry logs from Hive for date range
  static Future<List<EntryLog>> _getEntryLogs(
    DateTime startDate,
    DateTime endDate,
    {Set<String>? scheduleIds}
  ) async {
    final box = Hive.box<EntryLog>('entry_logs');

    return box.values
        .where(
          (log) =>
              (scheduleIds == null || scheduleIds.contains(log.scheduleId)) &&
              log.scheduledTime.isAfter(
                startDate.subtract(const Duration(hours: 1)),
              ) &&
              log.scheduledTime.isBefore(endDate.add(const Duration(hours: 1))),
        )
        .toList(growable: false);
  }

  /// Calculates all entry times for a single schedule in date range
  static List<CalculatedEntry> _calculateScheduleEntries(
    Schedule schedule,
    DateTime startDate,
    DateTime endDate,
  ) {
    final entries = <CalculatedEntry>[];
    final times = schedule.timesOfDay ?? [schedule.minutesOfDay];

    if (schedule.hasCycle) {
      // Cycle-based schedule
      entries.addAll(_calculateCycleEntries(schedule, times, startDate, endDate));
    } else if (schedule.hasDaysOfMonth) {
      entries.addAll(_calculateMonthlyEntries(schedule, times, startDate, endDate));
    } else {
      // Weekly pattern schedule
      entries.addAll(_calculateWeeklyEntries(schedule, times, startDate, endDate));
    }

    return entries;
  }

  /// Calculates entries for cycle-based schedules
  static List<CalculatedEntry> _calculateCycleEntries(
    Schedule schedule,
    List<int> times,
    DateTime startDate,
    DateTime endDate,
  ) {
    final entries = <CalculatedEntry>[];
    final cycleLength = schedule.cycleEveryNDays ?? 1;
    final anchorDate = schedule.cycleAnchorDate ?? startDate;

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final daysSinceAnchor = currentDate.difference(anchorDate).inDays;

      if (daysSinceAnchor >= 0 && daysSinceAnchor % cycleLength == 0) {
        // This is a entry day
        for (final minutesOfDay in times) {
          final hour = minutesOfDay ~/ 60;
          final minute = minutesOfDay % 60;
          final entryTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          if (_isInRange(schedule, entryTime, startDate, endDate)) {
            entries.add(
              CalculatedEntry(
                scheduleId: schedule.id,
                scheduleName: schedule.name,
                medicationName: schedule.medicationName,
                scheduledTime: entryTime,
                entryValue: schedule.entryValue,
                entryUnit: schedule.entryUnit,
              ),
            );
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return entries;
  }

  /// Calculates entries for weekly pattern schedules
  static List<CalculatedEntry> _calculateWeeklyEntries(
    Schedule schedule,
    List<int> times,
    DateTime startDate,
    DateTime endDate,
  ) {
    final entries = <CalculatedEntry>[];
    final daysOfWeek = schedule.daysOfWeek;

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final weekday = currentDate.weekday;

      if (daysOfWeek.contains(weekday)) {
        // This is a entry day
        for (final minutesOfDay in times) {
          final hour = minutesOfDay ~/ 60;
          final minute = minutesOfDay % 60;
          final entryTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          if (_isInRange(schedule, entryTime, startDate, endDate)) {
            entries.add(
              CalculatedEntry(
                scheduleId: schedule.id,
                scheduleName: schedule.name,
                medicationName: schedule.medicationName,
                scheduledTime: entryTime,
                entryValue: schedule.entryValue,
                entryUnit: schedule.entryUnit,
              ),
            );
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return entries;
  }

  static List<CalculatedEntry> _calculateMonthlyEntries(
    Schedule schedule,
    List<int> times,
    DateTime startDate,
    DateTime endDate,
  ) {
    final entries = <CalculatedEntry>[];

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (_isMonthlyEntryDay(schedule, currentDate)) {
        for (final minutesOfDay in times) {
          final hour = minutesOfDay ~/ 60;
          final minute = minutesOfDay % 60;
          final entryTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          if (_isInRange(schedule, entryTime, startDate, endDate)) {
            entries.add(
              CalculatedEntry(
                scheduleId: schedule.id,
                scheduleName: schedule.name,
                medicationName: schedule.medicationName,
                scheduledTime: entryTime,
                entryValue: schedule.entryValue,
                entryUnit: schedule.entryUnit,
              ),
            );
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return entries;
  }

  /// Checks if a time is within the date range
  static bool _isInRange(
    Schedule schedule,
    DateTime time,
    DateTime start,
    DateTime end,
  ) {
    final inWindow =
        (time.isAfter(start) || time.isAtSameMomentAs(start)) &&
        (time.isBefore(end) || time.isAtSameMomentAs(end));
    if (!inWindow) return false;

    final startAt = schedule.startAt;
    if (startAt != null && time.isBefore(startAt)) return false;
    final endAt = schedule.endAt;
    if (endAt != null && time.isAfter(endAt)) return false;

    // Suppress occurrences that fall within the paused window.
    final pausedUntil = schedule.pausedUntil;
    if (pausedUntil != null && time.isBefore(pausedUntil)) return false;

    return true;
  }

  static Map<String, Map<int, EntryLog>> _indexLogsByScheduleMinute(
    List<EntryLog> logs,
  ) {
    final index = <String, Map<int, EntryLog>>{};
    for (final log in logs) {
      final byMinute = index.putIfAbsent(log.scheduleId, () => <int, EntryLog>{});
      byMinute[_minuteKey(log.scheduledTime)] = log;
    }
    return index;
  }

  static EntryLog? _findMatchingLogIndexed(
    CalculatedEntry entry,
    Map<String, Map<int, EntryLog>> logIndex,
  ) {
    final byMinute = logIndex[entry.scheduleId];
    if (byMinute == null || byMinute.isEmpty) return null;

    final baseKey = _minuteKey(entry.scheduledTime);
    for (final candidateKey in <int>[baseKey - 1, baseKey, baseKey + 1]) {
      final log = byMinute[candidateKey];
      if (log == null) continue;
      final diff = log.scheduledTime.difference(entry.scheduledTime).abs();
      if (diff.inMinutes <= 1) return log;
    }

    return null;
  }

  /// Gets entries for a specific day
  static Future<List<CalculatedEntry>> getEntriesForDay(
    DateTime date, {
    String? scheduleId,
    String? medicationId,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return calculateEntries(
      startDate: startOfDay,
      endDate: endOfDay,
      scheduleId: scheduleId,
      medicationId: medicationId,
    );
  }

  /// Gets entries for a specific week (7 days starting from date)
  static Future<List<CalculatedEntry>> getEntriesForWeek(
    DateTime startDate, {
    String? scheduleId,
    String? medicationId,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = start.add(const Duration(days: 7));

    return calculateEntries(
      startDate: start,
      endDate: end,
      scheduleId: scheduleId,
      medicationId: medicationId,
    );
  }

  /// Gets entries for a specific month
  static Future<List<CalculatedEntry>> getEntriesForMonth(
    DateTime date, {
    String? scheduleId,
    String? medicationId,
  }) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    final endDate = DateTime(
      lastDay.year,
      lastDay.month,
      lastDay.day,
      23,
      59,
      59,
    );

    return calculateEntries(
      startDate: firstDay,
      endDate: endDate,
      scheduleId: scheduleId,
      medicationId: medicationId,
    );
  }

  /// Groups entries by day
  static Map<DateTime, List<CalculatedEntry>> groupEntriesByDay(
    List<CalculatedEntry> entries,
  ) {
    final grouped = <DateTime, List<CalculatedEntry>>{};

    for (final entry in entries) {
      final dayKey = DateTime(
        entry.scheduledTime.year,
        entry.scheduledTime.month,
        entry.scheduledTime.day,
      );

      grouped.putIfAbsent(dayKey, () => []).add(entry);
    }

    return grouped;
  }

  /// Groups entries by hour
  static Map<int, List<CalculatedEntry>> groupEntriesByHour(
    List<CalculatedEntry> entries,
  ) {
    final grouped = <int, List<CalculatedEntry>>{};

    for (final entry in entries) {
      grouped.putIfAbsent(entry.scheduledTime.hour, () => []).add(entry);
    }

    return grouped;
  }

  /// Gets statistics for entries in a date range
  static Future<EntryStatistics> getStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? scheduleId,
    String? medicationId,
  }) async {
    final entries = await calculateEntries(
      startDate: startDate,
      endDate: endDate,
      scheduleId: scheduleId,
      medicationId: medicationId,
    );

    final taken = entries.where((d) => d.isTaken).length;
    final skipped = entries.where((d) => d.isSkipped).length;
    final overdue = entries.where((d) => d.isOverdue).length;
    final pending = entries.where((d) => d.isPending).length;

    return EntryStatistics(
      total: entries.length,
      taken: taken,
      skipped: skipped,
      overdue: overdue,
      pending: pending,
    );
  }
}

/// Statistics for entries in a date range
class EntryStatistics {
  final int total;
  final int taken;
  final int skipped;
  final int overdue;
  final int pending;

  const EntryStatistics({
    required this.total,
    required this.taken,
    required this.skipped,
    required this.overdue,
    required this.pending,
  });

  /// Adherence rate (taken / (taken + skipped + overdue))
  double get adherenceRate {
    final completed = taken + skipped + overdue;
    if (completed == 0) return 0.0;
    return (taken / completed) * 100;
  }

  /// Completion rate (taken + skipped) / total)
  double get completionRate {
    if (total == 0) return 0.0;
    return ((taken + skipped) / total) * 100;
  }

  @override
  String toString() {
    return 'EntryStatistics{total: $total, taken: $taken, skipped: $skipped, '
        'overdue: $overdue, pending: $pending, adherence: ${adherenceRate.toStringAsFixed(1)}%}';
  }
}
