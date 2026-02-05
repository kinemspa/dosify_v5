// Project imports:
import 'package:dosifi_v5/src/core/notifications/dose_timing_settings.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';

/// Represents a calculated dose occurrence for calendar display
class CalculatedDose {
  final String scheduleId;
  final String scheduleName;
  final String medicationName;
  final DateTime scheduledTime;
  final double doseValue;
  final String doseUnit;
  final DoseLog? existingLog;

  const CalculatedDose({
    required this.scheduleId,
    required this.scheduleName,
    required this.medicationName,
    required this.scheduledTime,
    required this.doseValue,
    required this.doseUnit,
    this.existingLog,
  });

  /// Status of this dose based on whether it was taken
  DoseStatus get status {
    if (existingLog != null) {
      return DoseStatus.fromAction(existingLog!.action);
    }

    final now = DateTime.now();
    if (scheduledTime.isAfter(now)) return DoseStatus.pending;

    final missedAt = DoseTimingSettings.missedAtForScheduleId(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
    );

    if (now.isBefore(missedAt)) return DoseStatus.due;
    return DoseStatus.overdue;
  }

  /// Whether this dose has been taken
  bool get isTaken => existingLog?.action == DoseAction.taken;

  /// Whether this dose was skipped
  bool get isSkipped => existingLog?.action == DoseAction.skipped;

  /// Whether this dose was snoozed
  bool get isSnoozed => existingLog?.action == DoseAction.snoozed;

  /// Whether this dose is overdue (past scheduled time and not taken)
  bool get isOverdue => status == DoseStatus.overdue;

  /// Whether this dose is due/overdue but still within the grace window
  bool get isDue => status == DoseStatus.due;

  /// Whether this dose is pending (future and not taken)
  bool get isPending => status == DoseStatus.pending;

  /// Gets formatted dose description (e.g., "2 tablets", "500mcg")
  String get doseDescription => '$doseValue $doseUnit';

  /// Gets time of day formatted (e.g., "9:00 AM")
  String get timeFormatted {
    final hour = scheduledTime.hour == 0
        ? 12
        : scheduledTime.hour > 12
        ? scheduledTime.hour - 12
        : scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = scheduledTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Creates a copy with updated fields
  CalculatedDose copyWith({
    String? scheduleId,
    String? scheduleName,
    String? medicationName,
    DateTime? scheduledTime,
    double? doseValue,
    String? doseUnit,
    DoseLog? existingLog,
  }) {
    return CalculatedDose(
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleName: scheduleName ?? this.scheduleName,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      doseValue: doseValue ?? this.doseValue,
      doseUnit: doseUnit ?? this.doseUnit,
      existingLog: existingLog ?? this.existingLog,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatedDose &&
          runtimeType == other.runtimeType &&
          scheduleId == other.scheduleId &&
          scheduledTime == other.scheduledTime;

  @override
  int get hashCode => scheduleId.hashCode ^ scheduledTime.hashCode;

  @override
  String toString() {
    return 'CalculatedDose{$scheduleName at ${timeFormatted}, status: $status}';
  }
}

/// Status of a calculated dose
enum DoseStatus {
  /// Dose is in the future and not yet taken
  pending,

  /// Dose time has passed but is still within the grace window
  due,

  /// Dose was taken
  taken,

  /// Dose was skipped
  skipped,

  /// Dose was snoozed
  snoozed,

  /// Dose is past scheduled time and not taken
  overdue;

  /// Creates status from DoseAction
  static DoseStatus fromAction(DoseAction action) {
    switch (action) {
      case DoseAction.taken:
        return DoseStatus.taken;
      case DoseAction.skipped:
        return DoseStatus.skipped;
      case DoseAction.snoozed:
        return DoseStatus.snoozed;
    }
  }

  /// Whether this status indicates completion (taken or skipped)
  bool get isCompleted => this == taken || this == skipped;

  /// Whether this status requires attention (overdue or snoozed)
  bool get requiresAttention => this == overdue || this == due || this == snoozed;
}
