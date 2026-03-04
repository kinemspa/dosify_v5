// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/hive/hive_box_safe_write.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log_ids.dart';

class EntryLogRepository {
  EntryLogRepository(this._box);
  final Box<EntryLog> _box;

  static String occurrenceId({
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    return EntryLogIds.occurrenceId(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
    );
  }

  EntryLog? getForOccurrence({
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    final baseId = occurrenceId(scheduleId: scheduleId, scheduledTime: scheduledTime);
    return _box.get(baseId) ?? _box.get(EntryLogIds.legacySnoozeIdFromBase(baseId));
  }

  /// Get all entry logs
  List<EntryLog> getAll() => _box.values.toList(growable: false);

  /// Get logs for a specific schedule
  List<EntryLog> getByScheduleId(String scheduleId) {
    return _box.values
        .where((log) => log.scheduleId == scheduleId)
        .toList(growable: false);
  }

  /// Get logs for a specific medication
  List<EntryLog> getByMedicationId(String medicationId) {
    return _box.values
        .where((log) => log.medicationId == medicationId)
        .toList(growable: false);
  }

  /// Get logs within a date range
  List<EntryLog> getByDateRange(DateTime start, DateTime end) {
    return _box.values
        .where(
          (log) =>
              log.scheduledTime.isAfter(start) &&
              log.scheduledTime.isBefore(end),
        )
        .toList(growable: false);
  }

  /// Get logs for a specific day
  List<EntryLog> getByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getByDateRange(start, end);
  }

  /// Save or update a entry log
  Future<void> upsert(EntryLog log) => _box.putSafe(log.id, log);

  /// Save/update the log for a specific occurrence while preventing legacy
  /// duplicate snooze logs.
  Future<void> upsertOccurrence(EntryLog log) async {
    await _box.putSafe(log.id, log);

    // Migration cleanup: older builds wrote snooze logs under "${baseId}_snooze".
    // If we just wrote the base id, remove the legacy snooze id.
    final legacySnoozeId = EntryLogIds.legacySnoozeIdFromBase(log.id);
    if (legacySnoozeId != log.id && _box.containsKey(legacySnoozeId)) {
      await _box.deleteSafe(legacySnoozeId);
    }
  }

  Future<void> deleteOccurrence({
    required String scheduleId,
    required DateTime scheduledTime,
  }) async {
    final baseId = occurrenceId(scheduleId: scheduleId, scheduledTime: scheduledTime);
    await _box.deleteSafe(baseId);
    await _box.deleteSafe(EntryLogIds.legacySnoozeIdFromBase(baseId));
  }

  /// Delete a entry log (rarely used - logs should persist for reporting)
  Future<void> delete(String id) => _box.deleteSafe(id);

  /// Get adherence statistics for a schedule
  Map<String, dynamic> getAdherenceStats(String scheduleId) {
    final logs = getByScheduleId(scheduleId);
    final taken = logs.where((l) => l.action == EntryAction.logged).length;
    final skipped = logs.where((l) => l.action == EntryAction.skipped).length;
    final snoozed = logs.where((l) => l.action == EntryAction.snoozed).length;
    final onTime = logs.where((l) => l.wasOnTime).length;

    return {
      'total': logs.length,
      'logged': taken,
      'skipped': skipped,
      'snoozed': snoozed,
      'onTime': onTime,
      'adherenceRate': logs.isEmpty ? 0.0 : (taken / logs.length) * 100,
      'onTimeRate': taken == 0 ? 0.0 : (onTime / taken) * 100,
    };
  }
}
