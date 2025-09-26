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
    this.timesOfDay,
    this.timesOfDayUtc,
    this.cycleEveryNDays,
    this.cycleAnchorDate,
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
  @HiveField(8)
  final DateTime createdAt;

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
  final int? doseIU; // IU/units
  @HiveField(24)
  final int? displayUnitCode; // maps to DoseUnit index for display preference
  @HiveField(25)
  final int? inputModeCode; // maps to DoseInputMode index

  bool get hasUtc => minutesOfDayUtc != null && daysOfWeekUtc != null;
  bool get hasMultipleTimes => timesOfDay != null && timesOfDay!.isNotEmpty;
  bool get hasCycle => cycleEveryNDays != null && cycleEveryNDays! > 0;

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
  iu, // International Units
  units, // alias for IU if needed in UI
  tablets,
  capsules,
  syringes,
  vials,
}

enum DoseInputMode { tablets, capsules, mass, volume, iuUnits, count }
