// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

part 'entry_log.g.dart';

/// Records when a scheduled entry was logged, skipped, or snoozed.
/// Persists even if medication or schedule is deleted for historical reporting.
@HiveType(typeId: 41)
class EntryLog {
  EntryLog({
    required this.id,
    required this.scheduleId,
    required this.scheduleName,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.entryValue,
    required this.entryUnit,
    required this.action,
    this.actualEntryValue,
    this.actualEntryUnit,
    this.notes,
    DateTime? actionTime,
  }) : actionTime = actionTime ?? DateTime.now();

  @HiveField(0)
  final String id; // uuid

  @HiveField(1)
  final String scheduleId; // Reference to schedule (may be deleted)

  @HiveField(2)
  final String scheduleName; // Stored name for historical reporting

  @HiveField(3)
  final String medicationId; // Reference to medication (may be deleted)

  @HiveField(4)
  final String medicationName; // Stored name for historical reporting

  @HiveField(5)
  final DateTime scheduledTime; // When entry was supposed to be taken (UTC)

  @HiveField(6)
  final DateTime actionTime; // When action was recorded (UTC)

  @HiveField(7)
  final double entryValue; // Scheduled entry amount

  @HiveField(8)
  final String entryUnit; // Scheduled entry unit (mcg/mg/g/tablets/etc)

  @HiveField(9)
  final EntryAction action; // logged, skipped, snoozed

  @HiveField(10)
  final double? actualEntryValue; // Actual entry taken (if different from scheduled)

  @HiveField(11)
  final String? actualEntryUnit; // Actual entry unit (if different from scheduled)

  @HiveField(12)
  final String? notes; // Optional user notes

  /// Whether the entry was logged on time (within acceptable window)
  /// Acceptable window: within 30 minutes of scheduled time
  bool get wasOnTime {
    if (action != EntryAction.logged) return false;
    final difference = actionTime.difference(scheduledTime).abs();
    return difference.inMinutes <= 30;
  }

  /// Minutes early/late (positive = late, negative = early)
  int get minutesOffset {
    return actionTime.difference(scheduledTime).inMinutes;
  }

  /// Whether this log references a deleted schedule
  bool isOrphanedSchedule(List<String> activeScheduleIds) {
    return !activeScheduleIds.contains(scheduleId);
  }

  /// Whether this log references a deleted medication
  bool isOrphanedMedication(List<String> activeMedicationIds) {
    return !activeMedicationIds.contains(medicationId);
  }
}

@HiveType(typeId: 42)
enum EntryAction {
  @HiveField(0)
  logged, // was: taken — renamed for regulatory neutrality; Hive index unchanged

  @HiveField(1)
  skipped,

  @HiveField(2)
  snoozed,
}
