import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';

class DoseLogIds {
  const DoseLogIds._();

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
  static DoseLog? pickExistingFromMap(
    Map<String, DoseLog> byId, {
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    final base = occurrenceId(scheduleId: scheduleId, scheduledTime: scheduledTime);
    return byId[base] ?? byId[legacySnoozeIdFromBase(base)];
  }
}
