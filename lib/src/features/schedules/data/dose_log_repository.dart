// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';

class DoseLogRepository {
  DoseLogRepository(this._box);
  final Box<DoseLog> _box;

  /// Get all dose logs
  List<DoseLog> getAll() => _box.values.toList(growable: false);

  /// Get logs for a specific schedule
  List<DoseLog> getByScheduleId(String scheduleId) {
    return _box.values
        .where((log) => log.scheduleId == scheduleId)
        .toList(growable: false);
  }

  /// Get logs for a specific medication
  List<DoseLog> getByMedicationId(String medicationId) {
    return _box.values
        .where((log) => log.medicationId == medicationId)
        .toList(growable: false);
  }

  /// Get logs within a date range
  List<DoseLog> getByDateRange(DateTime start, DateTime end) {
    return _box.values
        .where(
          (log) =>
              log.scheduledTime.isAfter(start) &&
              log.scheduledTime.isBefore(end),
        )
        .toList(growable: false);
  }

  /// Get logs for a specific day
  List<DoseLog> getByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getByDateRange(start, end);
  }

  /// Save or update a dose log
  Future<void> upsert(DoseLog log) => _box.put(log.id, log);

  /// Delete a dose log (rarely used - logs should persist for reporting)
  Future<void> delete(String id) => _box.delete(id);

  /// Get adherence statistics for a schedule
  Map<String, dynamic> getAdherenceStats(String scheduleId) {
    final logs = getByScheduleId(scheduleId);
    final taken = logs.where((l) => l.action == DoseAction.taken).length;
    final skipped = logs.where((l) => l.action == DoseAction.skipped).length;
    final snoozed = logs.where((l) => l.action == DoseAction.snoozed).length;
    final onTime = logs.where((l) => l.wasOnTime).length;

    return {
      'total': logs.length,
      'taken': taken,
      'skipped': skipped,
      'snoozed': snoozed,
      'onTime': onTime,
      'adherenceRate': logs.isEmpty ? 0.0 : (taken / logs.length) * 100,
      'onTimeRate': taken == 0 ? 0.0 : (onTime / taken) * 100,
    };
  }
}
