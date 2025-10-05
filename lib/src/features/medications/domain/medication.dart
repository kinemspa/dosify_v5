import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

part 'medication.g.dart';

/// Represents an active reconstituted vial with short-term expiry
@HiveType(typeId: 11)
class ActiveVial {
  ActiveVial({
    required this.reconstitutionDate,
    required this.expiryDate,
    required this.volumeMl,
    required this.concentrationPerMl,
    this.diluentName,
    this.syringeSizeMl,
    this.recommendedUnits,
  });

  @HiveField(0)
  final DateTime reconstitutionDate;

  @HiveField(1)
  final DateTime expiryDate;

  @HiveField(2)
  final double volumeMl;

  @HiveField(3)
  final double concentrationPerMl;

  @HiveField(4)
  final String? diluentName;

  @HiveField(5)
  final double? syringeSizeMl;

  @HiveField(6)
  final double? recommendedUnits;

  ActiveVial copyWith({
    DateTime? reconstitutionDate,
    DateTime? expiryDate,
    double? volumeMl,
    double? concentrationPerMl,
    String? diluentName,
    double? syringeSizeMl,
    double? recommendedUnits,
  }) {
    return ActiveVial(
      reconstitutionDate: reconstitutionDate ?? this.reconstitutionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      volumeMl: volumeMl ?? this.volumeMl,
      concentrationPerMl: concentrationPerMl ?? this.concentrationPerMl,
      diluentName: diluentName ?? this.diluentName,
      syringeSizeMl: syringeSizeMl ?? this.syringeSizeMl,
      recommendedUnits: recommendedUnits ?? this.recommendedUnits,
    );
  }

  /// Check if vial is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Check if vial is approaching expiry (within 6 hours)
  bool get isApproachingExpiry {
    final now = DateTime.now();
    final sixHoursBeforeExpiry = expiryDate.subtract(const Duration(hours: 6));
    return now.isAfter(sixHoursBeforeExpiry) && now.isBefore(expiryDate);
  }

  /// Get time remaining until expiry
  Duration get timeUntilExpiry => expiryDate.difference(DateTime.now());
}

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
    this.lowStockVialVolumeThresholdMl,
    this.lowStockVialsThresholdCount,
    this.initialStockValue,
    this.activeVial,
  }) : createdAt = createdAt ?? DateTime.now(),
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

  // Multi-dose low stock thresholds
  // Threshold for the current vial liquid volume (mL)
  @HiveField(21)
  final double? lowStockVialVolumeThresholdMl;
  // Threshold for reserve vials count
  @HiveField(22)
  final double? lowStockVialsThresholdCount;

  // The originally entered stock amount when the medication was created or last restocked
  @HiveField(23)
  final double? initialStockValue;

  // Active reconstituted vial (for MDV only)
  @HiveField(24)
  final ActiveVial? activeVial;

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
    double? lowStockVialVolumeThresholdMl,
    double? lowStockVialsThresholdCount,
    double? initialStockValue,
    ActiveVial? activeVial,
    bool clearActiveVial = false,
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
      requiresRefrigeration:
          requiresRefrigeration ?? this.requiresRefrigeration,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      containerVolumeMl: containerVolumeMl ?? this.containerVolumeMl,
      lowStockVialVolumeThresholdMl:
          lowStockVialVolumeThresholdMl ?? this.lowStockVialVolumeThresholdMl,
      lowStockVialsThresholdCount:
          lowStockVialsThresholdCount ?? this.lowStockVialsThresholdCount,
      initialStockValue: initialStockValue ?? this.initialStockValue,
      activeVial: clearActiveVial ? null : (activeVial ?? this.activeVial),
    );
  }
}
