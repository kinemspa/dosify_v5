// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Service for calculating dose occurrences for calendar views
///
/// This service computes all scheduled dose times for a given date range
/// and matches them with existing dose logs to determine status.
class DoseCalculationService {
  /// Calculates all dose times for active schedules in a date range
  ///
  /// Returns a list of [CalculatedDose] objects sorted by scheduled time.
  /// Each dose includes its status based on whether it was logged.
  static Future<List<CalculatedDose>> calculateDoses({
    required DateTime startDate,
    required DateTime endDate,
    String? scheduleId,
    String? medicationId,
  }) async {
    final schedules = await _getSchedules(scheduleId, medicationId);
    final doseLogs = await _getDoseLogs(startDate, endDate);

    final doses = <CalculatedDose>[];

    for (final schedule in schedules) {
      if (!schedule.active) continue;

      final scheduleDoses = _calculateScheduleDoses(
        schedule,
        startDate,
        endDate,
      );

      // Match with existing logs
      for (final dose in scheduleDoses) {
        final log = _findMatchingLog(dose, doseLogs);
        doses.add(dose.copyWith(existingLog: log));
      }
    }

    // Sort by scheduled time
    doses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    debugPrint(
      '[DoseCalculationService] Calculated ${doses.length} doses for ${startDate.toLocal()} to ${endDate.toLocal()}',
    );

    return doses;
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

  /// Gets dose logs from Hive for date range
  static Future<List<DoseLog>> _getDoseLogs(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final box = Hive.box<DoseLog>('dose_logs');

    return box.values
        .where(
          (log) =>
              log.scheduledTime.isAfter(
                startDate.subtract(const Duration(hours: 1)),
              ) &&
              log.scheduledTime.isBefore(endDate.add(const Duration(hours: 1))),
        )
        .toList(growable: false);
  }

  /// Calculates all dose times for a single schedule in date range
  static List<CalculatedDose> _calculateScheduleDoses(
    Schedule schedule,
    DateTime startDate,
    DateTime endDate,
  ) {
    final doses = <CalculatedDose>[];
    final times = schedule.timesOfDay ?? [schedule.minutesOfDay];

    if (schedule.hasCycle) {
      // Cycle-based schedule
      doses.addAll(_calculateCycleDoses(schedule, times, startDate, endDate));
    } else {
      // Weekly pattern schedule
      doses.addAll(_calculateWeeklyDoses(schedule, times, startDate, endDate));
    }

    return doses;
  }

  /// Calculates doses for cycle-based schedules
  static List<CalculatedDose> _calculateCycleDoses(
    Schedule schedule,
    List<int> times,
    DateTime startDate,
    DateTime endDate,
  ) {
    final doses = <CalculatedDose>[];
    final cycleLength = schedule.cycleEveryNDays ?? 1;
    final anchorDate = schedule.cycleAnchorDate ?? startDate;

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
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

          if (_isInRange(doseTime, startDate, endDate)) {
            doses.add(
              CalculatedDose(
                scheduleId: schedule.id,
                scheduleName: schedule.name,
                medicationName: schedule.medicationName,
                scheduledTime: doseTime,
                doseValue: schedule.doseValue,
                doseUnit: schedule.doseUnit,
              ),
            );
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return doses;
  }

  /// Calculates doses for weekly pattern schedules
  static List<CalculatedDose> _calculateWeeklyDoses(
    Schedule schedule,
    List<int> times,
    DateTime startDate,
    DateTime endDate,
  ) {
    final doses = <CalculatedDose>[];
    final daysOfWeek = schedule.daysOfWeek;

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final weekday = currentDate.weekday;

      if (daysOfWeek.contains(weekday)) {
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

          if (_isInRange(doseTime, startDate, endDate)) {
            doses.add(
              CalculatedDose(
                scheduleId: schedule.id,
                scheduleName: schedule.name,
                medicationName: schedule.medicationName,
                scheduledTime: doseTime,
                doseValue: schedule.doseValue,
                doseUnit: schedule.doseUnit,
              ),
            );
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return doses;
  }

  /// Checks if a time is within the date range
  static bool _isInRange(DateTime time, DateTime start, DateTime end) {
    return (time.isAfter(start) || time.isAtSameMomentAs(start)) &&
        (time.isBefore(end) || time.isAtSameMomentAs(end));
  }

  /// Finds a dose log that matches the calculated dose
  ///
  /// Matches based on scheduleId and scheduled time (within 1-minute window)
  static DoseLog? _findMatchingLog(CalculatedDose dose, List<DoseLog> logs) {
    return logs.cast<DoseLog?>().firstWhere((log) {
      if (log == null) return false;
      if (log.scheduleId != dose.scheduleId) return false;

      // Match if within 1 minute of scheduled time
      final diff = log.scheduledTime.difference(dose.scheduledTime).abs();
      return diff.inMinutes <= 1;
    }, orElse: () => null);
  }

  /// Gets doses for a specific day
  static Future<List<CalculatedDose>> getDosesForDay(
    DateTime date, {
    String? scheduleId,
    String? medicationId,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return calculateDoses(
      startDate: startOfDay,
      endDate: endOfDay,
      scheduleId: scheduleId,
      medicationId: medicationId,
    );
  }

  /// Gets doses for a specific week (7 days starting from date)
  static Future<List<CalculatedDose>> getDosesForWeek(
    DateTime startDate, {
    String? scheduleId,
    String? medicationId,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = start.add(const Duration(days: 7));

    return calculateDoses(
      startDate: start,
      endDate: end,
      scheduleId: scheduleId,
      medicationId: medicationId,
    );
  }

  /// Gets doses for a specific month
  static Future<List<CalculatedDose>> getDosesForMonth(
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

    return calculateDoses(
      startDate: firstDay,
      endDate: endDate,
      scheduleId: scheduleId,
      medicationId: medicationId,
    );
  }

  /// Groups doses by day
  static Map<DateTime, List<CalculatedDose>> groupDosesByDay(
    List<CalculatedDose> doses,
  ) {
    final grouped = <DateTime, List<CalculatedDose>>{};

    for (final dose in doses) {
      final dayKey = DateTime(
        dose.scheduledTime.year,
        dose.scheduledTime.month,
        dose.scheduledTime.day,
      );

      grouped.putIfAbsent(dayKey, () => []).add(dose);
    }

    return grouped;
  }

  /// Groups doses by hour
  static Map<int, List<CalculatedDose>> groupDosesByHour(
    List<CalculatedDose> doses,
  ) {
    final grouped = <int, List<CalculatedDose>>{};

    for (final dose in doses) {
      grouped.putIfAbsent(dose.scheduledTime.hour, () => []).add(dose);
    }

    return grouped;
  }

  /// Gets statistics for doses in a date range
  static Future<DoseStatistics> getStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? scheduleId,
    String? medicationId,
  }) async {
    final doses = await calculateDoses(
      startDate: startDate,
      endDate: endDate,
      scheduleId: scheduleId,
      medicationId: medicationId,
    );

    final taken = doses.where((d) => d.isTaken).length;
    final skipped = doses.where((d) => d.isSkipped).length;
    final overdue = doses.where((d) => d.isOverdue).length;
    final pending = doses.where((d) => d.isPending).length;

    return DoseStatistics(
      total: doses.length,
      taken: taken,
      skipped: skipped,
      overdue: overdue,
      pending: pending,
    );
  }
}

/// Statistics for doses in a date range
class DoseStatistics {
  final int total;
  final int taken;
  final int skipped;
  final int overdue;
  final int pending;

  const DoseStatistics({
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
    return 'DoseStatistics{total: $total, taken: $taken, skipped: $skipped, '
        'overdue: $overdue, pending: $pending, adherence: ${adherenceRate.toStringAsFixed(1)}%}';
  }
}
