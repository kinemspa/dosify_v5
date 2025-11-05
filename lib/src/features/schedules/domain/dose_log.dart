// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

part 'dose_log.g.dart';

/// Records when a scheduled dose was taken, skipped, or snoozed.
/// Persists even if medication or schedule is deleted for historical reporting.
@HiveType(typeId: 41)
class DoseLog {
  DoseLog({
    required this.id,
    required this.scheduleId,
    required this.scheduleName,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.doseValue,
    required this.doseUnit,
    required this.action,
    this.actualDoseValue,
    this.actualDoseUnit,
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
  final DateTime scheduledTime; // When dose was supposed to be taken (UTC)

  @HiveField(6)
  final DateTime actionTime; // When action was recorded (UTC)

  @HiveField(7)
  final double doseValue; // Scheduled dose amount

  @HiveField(8)
  final String doseUnit; // Scheduled dose unit (mcg/mg/g/tablets/etc)

  @HiveField(9)
  final DoseAction action; // taken, skipped, snoozed

  @HiveField(10)
  final double? actualDoseValue; // Actual dose taken (if different from scheduled)

  @HiveField(11)
  final String? actualDoseUnit; // Actual dose unit (if different from scheduled)

  @HiveField(12)
  final String? notes; // Optional user notes

  /// Whether the dose was taken on time (within acceptable window)
  /// Acceptable window: within 30 minutes of scheduled time
  bool get wasOnTime {
    if (action != DoseAction.taken) return false;
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
enum DoseAction {
  @HiveField(0)
  taken,

  @HiveField(1)
  skipped,

  @HiveField(2)
  snoozed,
}
