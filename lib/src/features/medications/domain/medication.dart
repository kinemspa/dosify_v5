import 'package:hive_flutter/hive_flutter.dart';
import 'enums.dart';

part 'medication.g.dart';

@HiveType(typeId: 10)
class Medication {
  Medication({
    required this.id,
    required this.form,
    required this.name,
    this.manufacturer,
    this.description,
    this.notes,
    required this.strengthValue,
    required this.strengthUnit,
    this.perMlValue,
    required this.stockValue,
    required this.stockUnit,
    this.lowStockEnabled = false,
    this.lowStockThreshold,
    this.expiry,
    this.batchNumber,
    this.storageLocation,
    this.requiresRefrigeration = false,
    this.storageInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.containerVolumeMl,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  final String id; // uuid

  @HiveField(1)
  final MedicationForm form;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? manufacturer;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final double strengthValue;

  @HiveField(7)
  final Unit strengthUnit;

  // Used when strengthUnit is a per mL unit
  @HiveField(8)
  final double? perMlValue;

  @HiveField(9)
  final double stockValue;

  @HiveField(10)
  final StockUnit stockUnit;

  @HiveField(11)
  final bool lowStockEnabled;

  @HiveField(12)
  final double? lowStockThreshold;

  @HiveField(13)
  final DateTime? expiry;

  @HiveField(14)
  final String? batchNumber;

  @HiveField(15)
  final String? storageLocation;

  @HiveField(16)
  final bool requiresRefrigeration;

  @HiveField(17)
  final String? storageInstructions;

  @HiveField(18)
  final DateTime createdAt;

  @HiveField(19)
  final DateTime updatedAt;

  // For multi-dose vials: resulting total vial volume (mL) after reconstitution
  @HiveField(20)
  final double? containerVolumeMl;

  Medication copyWith({
    String? id,
    MedicationForm? form,
    String? name,
    String? manufacturer,
    String? description,
    String? notes,
    double? strengthValue,
    Unit? strengthUnit,
    double? perMlValue,
    double? stockValue,
    StockUnit? stockUnit,
    bool? lowStockEnabled,
    double? lowStockThreshold,
    DateTime? expiry,
    String? batchNumber,
    String? storageLocation,
    bool? requiresRefrigeration,
    String? storageInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? containerVolumeMl,
  }) {
    return Medication(
      id: id ?? this.id,
      form: form ?? this.form,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      strengthValue: strengthValue ?? this.strengthValue,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      perMlValue: perMlValue ?? this.perMlValue,
      stockValue: stockValue ?? this.stockValue,
      stockUnit: stockUnit ?? this.stockUnit,
      lowStockEnabled: lowStockEnabled ?? this.lowStockEnabled,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      expiry: expiry ?? this.expiry,
      batchNumber: batchNumber ?? this.batchNumber,
      storageLocation: storageLocation ?? this.storageLocation,
      requiresRefrigeration: requiresRefrigeration ?? this.requiresRefrigeration,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      containerVolumeMl: containerVolumeMl ?? this.containerVolumeMl,
    );
  }
}

