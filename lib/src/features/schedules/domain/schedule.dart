// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

part 'schedule.g.dart';

@HiveType(typeId: 40)
class Schedule {
  Schedule({
    required this.id,
    required this.name,
    required this.medicationName,
    required this.doseValue,
    required this.doseUnit,
    required this.minutesOfDay,
    required this.daysOfWeek,
    this.minutesOfDayUtc,
    this.daysOfWeekUtc,
    this.medicationId,
    this.active = true,
    this.pausedUntil,
    this.timesOfDay,
    this.timesOfDayUtc,
    this.cycleEveryNDays,
    this.cycleAnchorDate,
    this.daysOfMonth,
    // New typed dose fields (all optional for backward compatibility)
    this.doseUnitCode,
    this.doseMassMcg,
    this.doseVolumeMicroliter,
    this.doseTabletQuarters,
    this.doseCapsules,
    this.doseSyringes,
    this.doseVials,
    this.doseIU,
    this.displayUnitCode,
    this.inputModeCode,
    this.startAt,
    this.endAt,
    this.monthlyMissingDayBehaviorCode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @HiveField(0)
  final String id; // uuid
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String medicationName;
  @HiveField(3)
  final double doseValue;
  @HiveField(4)
  final String doseUnit; // mcg/mg/g/units/tablets/capsules/pfs/vial
  @HiveField(5)
  final int minutesOfDay; // 0..1439 (local, legacy)
  @HiveField(6)
  final List<int> daysOfWeek; // 1=Mon..7=Sun (local, legacy)
  @HiveField(7)
  final bool active;

  /// If set and [active] is false, the schedule is paused until this moment.
  ///
  /// When this moment is in the past, the schedule may be auto-resumed by the
  /// scheduler on app startup.
  @HiveField(30)
  final DateTime? pausedUntil;
  @HiveField(8)
  final DateTime createdAt;

  /// Optional schedule start boundary.
  ///
  /// If set, occurrences before this moment are ignored.
  @HiveField(27)
  final DateTime? startAt;

  /// Optional schedule end boundary.
  ///
  /// If set, occurrences after this moment are ignored.
  @HiveField(28)
  final DateTime? endAt;

  /// Monthly schedules (days-of-month): what to do when a selected day does not
  /// exist in a given month (e.g., 31st in April).
  ///
  /// Stored as an int code to avoid introducing a new adapter.
  @HiveField(29)
  final int? monthlyMissingDayBehaviorCode;

  // UTC storage (new)
  @HiveField(9)
  final int? minutesOfDayUtc; // 0..1439 (UTC)
  @HiveField(10)
  final List<int>? daysOfWeekUtc; // 1=Mon..7=Sun (UTC)

  // Link to a saved medication (optional but recommended)
  @HiveField(11)
  final String? medicationId;

  // Multiple times per day (local minutes)
  @HiveField(12)
  final List<int>? timesOfDay;
  // Multiple times per day (UTC minutes)
  @HiveField(13)
  final List<int>? timesOfDayUtc;

  // Every N days cycle (if set, daysOfWeek is ignored)
  @HiveField(14)
  final int? cycleEveryNDays; // e.g., 2 -> every 2 days
  @HiveField(15)
  final DateTime? cycleAnchorDate; // local date anchor for cycle (midnight)

  // Days of month (1-31, if set daysOfWeek is ignored)
  @HiveField(26)
  final List<int>? daysOfMonth; // e.g., [1, 15] for 1st and 15th of each month

  // Typed dose fields (persisted as primitives to avoid new adapters)
  @HiveField(16)
  final int? doseUnitCode; // maps to DoseUnit index
  @HiveField(17)
  final int? doseMassMcg; // micrograms
  @HiveField(18)
  final int? doseVolumeMicroliter; // microliters
  @HiveField(19)
  final int? doseTabletQuarters; // 1 tab = 4 quarters
  @HiveField(20)
  final int? doseCapsules; // whole capsules
  @HiveField(21)
  final int? doseSyringes; // whole syringes
  @HiveField(22)
  final int? doseVials; // whole vials (single-dose)
  @HiveField(23)
  final int? doseIU; // units (medication potency)
  @HiveField(24)
  final int? displayUnitCode; // maps to DoseUnit index for display preference
  @HiveField(25)
  final int? inputModeCode; // maps to DoseInputMode index

  bool get hasUtc => minutesOfDayUtc != null && daysOfWeekUtc != null;
  bool get hasMultipleTimes => timesOfDay != null && timesOfDay!.isNotEmpty;
  bool get hasCycle => cycleEveryNDays != null && cycleEveryNDays! > 0;
  bool get hasDaysOfMonth => daysOfMonth != null && daysOfMonth!.isNotEmpty;

  bool get hasStartAt => startAt != null;
  bool get hasEndAt => endAt != null;

  ScheduleStatus get status {
    final now = DateTime.now();
    final end = endAt;
    if (end != null && end.isBefore(now)) {
      return ScheduleStatus.completed;
    }
    if (active) return ScheduleStatus.active;
    final until = pausedUntil;
    if (until != null && until.isAfter(now)) {
      return ScheduleStatus.paused;
    }
    return ScheduleStatus.disabled;
  }

  bool get isActive => status == ScheduleStatus.active;
  bool get isPaused => status == ScheduleStatus.paused;
  bool get isDisabled => status == ScheduleStatus.disabled;
  bool get isCompleted => status == ScheduleStatus.completed;

  static const Object _noChange = Object();

  Schedule copyWith({bool? active, Object? pausedUntil = _noChange}) {
    return Schedule(
      id: id,
      name: name,
      medicationName: medicationName,
      doseValue: doseValue,
      doseUnit: doseUnit,
      minutesOfDay: minutesOfDay,
      daysOfWeek: daysOfWeek,
      minutesOfDayUtc: minutesOfDayUtc,
      daysOfWeekUtc: daysOfWeekUtc,
      medicationId: medicationId,
      active: active ?? this.active,
      pausedUntil: pausedUntil == _noChange
          ? this.pausedUntil
          : pausedUntil as DateTime?,
      timesOfDay: timesOfDay,
      timesOfDayUtc: timesOfDayUtc,
      cycleEveryNDays: cycleEveryNDays,
      cycleAnchorDate: cycleAnchorDate,
      daysOfMonth: daysOfMonth,
      doseUnitCode: doseUnitCode,
      doseMassMcg: doseMassMcg,
      doseVolumeMicroliter: doseVolumeMicroliter,
      doseTabletQuarters: doseTabletQuarters,
      doseCapsules: doseCapsules,
      doseSyringes: doseSyringes,
      doseVials: doseVials,
      doseIU: doseIU,
      displayUnitCode: displayUnitCode,
      inputModeCode: inputModeCode,
      startAt: startAt,
      endAt: endAt,
      monthlyMissingDayBehaviorCode: monthlyMissingDayBehaviorCode,
      createdAt: createdAt,
    );
  }

  Schedule copyWithDetails({
    String? name,
    String? medicationName,
    double? doseValue,
    String? doseUnit,
    int? minutesOfDay,
    List<int>? daysOfWeek,
    Object? timesOfDay = _noChange,
    Object? timesOfDayUtc = _noChange,
    Object? cycleEveryNDays = _noChange,
    Object? cycleAnchorDate = _noChange,
    Object? daysOfMonth = _noChange,
    Object? startAt = _noChange,
    Object? endAt = _noChange,
    Object? monthlyMissingDayBehaviorCode = _noChange,
    bool? active,
    Object? pausedUntil = _noChange,
  }) {
    return Schedule(
      id: id,
      name: name ?? this.name,
      medicationName: medicationName ?? this.medicationName,
      doseValue: doseValue ?? this.doseValue,
      doseUnit: doseUnit ?? this.doseUnit,
      minutesOfDay: minutesOfDay ?? this.minutesOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      minutesOfDayUtc: minutesOfDayUtc,
      daysOfWeekUtc: daysOfWeekUtc,
      medicationId: medicationId,
      active: active ?? this.active,
      pausedUntil: pausedUntil == _noChange
          ? this.pausedUntil
          : pausedUntil as DateTime?,
      timesOfDay: timesOfDay == _noChange
          ? this.timesOfDay
          : timesOfDay as List<int>?,
      timesOfDayUtc: timesOfDayUtc == _noChange
          ? this.timesOfDayUtc
          : timesOfDayUtc as List<int>?,
      cycleEveryNDays: cycleEveryNDays == _noChange
          ? this.cycleEveryNDays
          : cycleEveryNDays as int?,
      cycleAnchorDate: cycleAnchorDate == _noChange
          ? this.cycleAnchorDate
          : cycleAnchorDate as DateTime?,
      daysOfMonth: daysOfMonth == _noChange
          ? this.daysOfMonth
          : daysOfMonth as List<int>?,
      doseUnitCode: doseUnitCode,
      doseMassMcg: doseMassMcg,
      doseVolumeMicroliter: doseVolumeMicroliter,
      doseTabletQuarters: doseTabletQuarters,
      doseCapsules: doseCapsules,
      doseSyringes: doseSyringes,
      doseVials: doseVials,
      doseIU: doseIU,
      displayUnitCode: displayUnitCode,
      inputModeCode: inputModeCode,
      startAt: startAt == _noChange ? this.startAt : startAt as DateTime?,
      endAt: endAt == _noChange ? this.endAt : endAt as DateTime?,
      monthlyMissingDayBehaviorCode: monthlyMissingDayBehaviorCode == _noChange
          ? this.monthlyMissingDayBehaviorCode
          : monthlyMissingDayBehaviorCode as int?,
      createdAt: createdAt,
    );
  }

  MonthlyMissingDayBehavior get monthlyMissingDayBehavior {
    final code = monthlyMissingDayBehaviorCode;
    if (code == null) return MonthlyMissingDayBehavior.skip;
    if (code < 0 || code >= MonthlyMissingDayBehavior.values.length) {
      return MonthlyMissingDayBehavior.skip;
    }
    return MonthlyMissingDayBehavior.values[code];
  }

  // Convenience getters (renamed to avoid shadowing legacy doseUnit String field)
  DoseUnit? get doseUnitEnum =>
      doseUnitCode != null ? DoseUnit.values[doseUnitCode!] : null;
  DoseUnit? get displayUnitEnum =>
      displayUnitCode != null ? DoseUnit.values[displayUnitCode!] : null;
  DoseInputMode? get inputModeEnum =>
      inputModeCode != null ? DoseInputMode.values[inputModeCode!] : null;
}

// Typed units and input modes (not Hive-annotated; persisted as int codes)
enum DoseUnit {
  mcg,
  mg,
  g,
  ml,
  iu, // units (medication potency)
  units, // alias for iu if needed in UI
  tablets,
  capsules,
  syringes,
  vials,
}

enum DoseInputMode { tablets, capsules, mass, volume, iuUnits, count }

enum MonthlyMissingDayBehavior {
  /// Skip the month if the selected day does not exist (legacy behavior).
  skip,

  /// Move the dose to the last day of the month.
  lastDay,
}

enum ScheduleStatus { active, paused, disabled, completed }
