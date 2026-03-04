// Project imports:
import 'package:dosifi_v5/src/core/notifications/entry_timing_settings.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log.dart';

/// Represents a calculated entry occurrence for calendar display
class CalculatedEntry {
  final String scheduleId;
  final String scheduleName;
  final String medicationName;
  final DateTime scheduledTime;
  final double entryValue;
  final String entryUnit;
  final EntryLog? existingLog;

  const CalculatedEntry({
    required this.scheduleId,
    required this.scheduleName,
    required this.medicationName,
    required this.scheduledTime,
    required this.entryValue,
    required this.entryUnit,
    this.existingLog,
  });

  /// Status of this entry based on whether it was taken
  EntryStatus get status {
    if (existingLog != null) {
      return EntryStatus.fromAction(existingLog!.action);
    }

    final now = DateTime.now();
    if (scheduledTime.isAfter(now)) return EntryStatus.pending;

    final missedAt = EntryTimingSettings.missedAtForScheduleId(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
    );

    if (now.isBefore(missedAt)) return EntryStatus.due;
    return EntryStatus.overdue;
  }

  /// Whether this entry has been logged
  bool get isTaken => existingLog?.action == EntryAction.logged;

  /// Whether this entry was skipped
  bool get isSkipped => existingLog?.action == EntryAction.skipped;

  /// Whether this entry was snoozed
  bool get isSnoozed => existingLog?.action == EntryAction.snoozed;

  /// Whether this entry is overdue (past scheduled time and not taken)
  bool get isOverdue => status == EntryStatus.overdue;

  /// Whether this entry is due/overdue but still within the grace window
  bool get isDue => status == EntryStatus.due;

  /// Whether this entry is pending (future and not taken)
  bool get isPending => status == EntryStatus.pending;

  /// Gets formatted entry description (e.g., "2 tablets", "500mcg")
  String get entryDescription => '$entryValue $entryUnit';

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
  CalculatedEntry copyWith({
    String? scheduleId,
    String? scheduleName,
    String? medicationName,
    DateTime? scheduledTime,
    double? entryValue,
    String? entryUnit,
    EntryLog? existingLog,
  }) {
    return CalculatedEntry(
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleName: scheduleName ?? this.scheduleName,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      entryValue: entryValue ?? this.entryValue,
      entryUnit: entryUnit ?? this.entryUnit,
      existingLog: existingLog ?? this.existingLog,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatedEntry &&
          runtimeType == other.runtimeType &&
          scheduleId == other.scheduleId &&
          scheduledTime == other.scheduledTime;

  @override
  int get hashCode => scheduleId.hashCode ^ scheduledTime.hashCode;

  @override
  String toString() {
    return 'CalculatedEntry{$scheduleName at ${timeFormatted}, status: $status}';
  }
}

/// Status of a calculated entry
enum EntryStatus {
  /// Entry is in the future and not yet taken
  pending,

  /// Entry time has passed but is still within the grace window
  due,

  /// Entry was logged
  logged,

  /// Entry was skipped
  skipped,

  /// Entry was snoozed
  snoozed,

  /// Entry is past scheduled time and not taken
  overdue;

  /// Creates status from EntryAction
  static EntryStatus fromAction(EntryAction action) {
    switch (action) {
      case EntryAction.logged:
        return EntryStatus.logged;
      case EntryAction.skipped:
        return EntryStatus.skipped;
      case EntryAction.snoozed:
        return EntryStatus.snoozed;
    }
  }

  /// Whether this status indicates completion (logged or skipped)
  bool get isCompleted => this == logged || this == skipped;

  /// Whether this status requires attention (overdue or snoozed)
  bool get requiresAttention => this == overdue || this == due || this == snoozed;
}
