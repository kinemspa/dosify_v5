import 'package:skedux/src/features/schedules/domain/entry_log.dart';

class EntryLogIds {
  const EntryLogIds._();

  static String occurrenceId({
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    return '${scheduleId}_${scheduledTime.millisecondsSinceEpoch}';
  }

  static String legacySnoozeIdFromBase(String baseId) => '${baseId}_snooze';

  static String legacySnoozeId({
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    return legacySnoozeIdFromBase(
      occurrenceId(scheduleId: scheduleId, scheduledTime: scheduledTime),
    );
  }

  /// Pure helper to pick the "existing" log for an occurrence.
  ///
  /// Prefers the base occurrence id, but falls back to legacy snooze id.
  static EntryLog? pickExistingFromMap(
    Map<String, EntryLog> byId, {
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    final base = occurrenceId(scheduleId: scheduleId, scheduledTime: scheduledTime);
    return byId[base] ?? byId[legacySnoozeIdFromBase(base)];
  }
}
