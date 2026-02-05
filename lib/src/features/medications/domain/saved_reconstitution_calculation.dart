// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 60)
class SavedReconstitutionCalculation {
  SavedReconstitutionCalculation({
    required this.id,
    required this.name,
    required this.strengthValue,
    required this.strengthUnit,
    required this.solventVolumeMl,
    required this.perMlConcentration,
    required this.recommendedUnits,
    required this.syringeSizeMl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.ownerMedicationId,
    this.medicationName,
    this.diluentName,
    this.recommendedDose,
    this.doseUnit,
    this.maxVialSizeMl,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// When set, this saved reconstitution is owned by a specific medication and
  /// should be deleted when the parent medication is deleted.
  ///
  /// Standalone saved reconstitutions should leave this null even if they set
  /// [medicationName] for display/search purposes.
  @HiveField(15)
  final String? ownerMedicationId;

  @HiveField(2)
  final String? medicationName;

  /// Total drug amount in the vial (before reconstitution)
  @HiveField(3)
  final double strengthValue;

  /// Unit for [strengthValue] (e.g. mcg, mg, g, units)
  @HiveField(4)
  final String strengthUnit;

  /// mL of solvent/diluent to add
  @HiveField(5)
  final double solventVolumeMl;

  /// Concentration per mL (same base unit as strength/dose)
  @HiveField(6)
  final double perMlConcentration;

  /// Syringe units (0-100 per mL mapping) recommended for the dose
  @HiveField(7)
  final double recommendedUnits;

  /// Selected syringe size in mL (e.g. 0.3, 0.5, 1.0, 3.0, 5.0)
  @HiveField(8)
  final double syringeSizeMl;

  @HiveField(9)
  final String? diluentName;

  /// Desired dose value (for reopening calculator)
  @HiveField(10)
  final double? recommendedDose;

  /// Dose unit (mcg/mg/g/units) for reopening calculator
  @HiveField(11)
  final String? doseUnit;

  /// Optional max vial size constraint (for reopening calculator)
  @HiveField(12)
  final double? maxVialSizeMl;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  SavedReconstitutionCalculation copyWith({
    String? id,
    String? name,
    String? ownerMedicationId,
    String? medicationName,
    double? strengthValue,
    String? strengthUnit,
    double? solventVolumeMl,
    double? perMlConcentration,
    double? recommendedUnits,
    double? syringeSizeMl,
    String? diluentName,
    double? recommendedDose,
    String? doseUnit,
    double? maxVialSizeMl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedReconstitutionCalculation(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerMedicationId: ownerMedicationId ?? this.ownerMedicationId,
      medicationName: medicationName ?? this.medicationName,
      strengthValue: strengthValue ?? this.strengthValue,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      solventVolumeMl: solventVolumeMl ?? this.solventVolumeMl,
      perMlConcentration: perMlConcentration ?? this.perMlConcentration,
      recommendedUnits: recommendedUnits ?? this.recommendedUnits,
      syringeSizeMl: syringeSizeMl ?? this.syringeSizeMl,
      diluentName: diluentName ?? this.diluentName,
      recommendedDose: recommendedDose ?? this.recommendedDose,
      doseUnit: doseUnit ?? this.doseUnit,
      maxVialSizeMl: maxVialSizeMl ?? this.maxVialSizeMl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SavedReconstitutionCalculationAdapter
    extends TypeAdapter<SavedReconstitutionCalculation> {
  @override
  final int typeId = 60;

  @override
  SavedReconstitutionCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return SavedReconstitutionCalculation(
      id: fields[0] as String,
      name: fields[1] as String,
      ownerMedicationId: fields[15] as String?,
      medicationName: fields[2] as String?,
      strengthValue: fields[3] as double,
      strengthUnit: fields[4] as String,
      solventVolumeMl: fields[5] as double,
      perMlConcentration: fields[6] as double,
      recommendedUnits: fields[7] as double,
      syringeSizeMl: fields[8] as double,
      diluentName: fields[9] as String?,
      recommendedDose: fields[10] as double?,
      doseUnit: fields[11] as String?,
      maxVialSizeMl: fields[12] as double?,
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedReconstitutionCalculation obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.medicationName)
      ..writeByte(3)
      ..write(obj.strengthValue)
      ..writeByte(4)
      ..write(obj.strengthUnit)
      ..writeByte(5)
      ..write(obj.solventVolumeMl)
      ..writeByte(6)
      ..write(obj.perMlConcentration)
      ..writeByte(7)
      ..write(obj.recommendedUnits)
      ..writeByte(8)
      ..write(obj.syringeSizeMl)
      ..writeByte(9)
      ..write(obj.diluentName)
      ..writeByte(10)
      ..write(obj.recommendedDose)
      ..writeByte(11)
      ..write(obj.doseUnit)
      ..writeByte(12)
      ..write(obj.maxVialSizeMl)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.ownerMedicationId);
  }
}
