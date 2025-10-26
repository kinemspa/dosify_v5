// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

part 'medication.g.dart';

@HiveType(typeId: 10)
class Medication {
  Medication({
    required this.id,
    required this.form,
    required this.name,
    required this.strengthValue,
    required this.strengthUnit,
    required this.stockValue,
    required this.stockUnit,
    this.manufacturer,
    this.description,
    this.notes,
    this.perMlValue,
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
    this.reconstitutedAt,
    this.reconstitutedVialExpiry,
    this.activeVialLowStockMl,
    this.activeVialBatchNumber,
    this.activeVialStorageLocation,
    this.activeVialRequiresRefrigeration = false,
    this.activeVialRequiresFreezer = false,
    this.activeVialLightSensitive = false,
    this.backupVialsExpiry,
    this.backupVialsBatchNumber,
    this.backupVialsStorageLocation,
    this.backupVialsRequiresRefrigeration = false,
    this.backupVialsRequiresFreezer = false,
    this.backupVialsLightSensitive = false,
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

  // For reconstituted MDV: when the current vial was reconstituted
  @HiveField(24)
  final DateTime? reconstitutedAt;

  // For reconstituted MDV: when the current reconstituted vial expires (typically 48hr after reconstitution)
  @HiveField(25)
  final DateTime? reconstitutedVialExpiry;

  // Active/Reconstituted vial fields (MDV only)
  @HiveField(26)
  final double? activeVialLowStockMl; // Low stock threshold for active vial volume in mL
  
  @HiveField(27)
  final String? activeVialBatchNumber;
  
  @HiveField(28)
  final String? activeVialStorageLocation;
  
  @HiveField(29)
  final bool activeVialRequiresRefrigeration;
  
  @HiveField(30)
  final bool activeVialRequiresFreezer;
  
  @HiveField(31)
  final bool activeVialLightSensitive;

  // Backup stock vials fields (MDV only)
  @HiveField(32)
  final DateTime? backupVialsExpiry; // Expiry for sealed backup vials
  
  @HiveField(33)
  final String? backupVialsBatchNumber;
  
  @HiveField(34)
  final String? backupVialsStorageLocation;
  
  @HiveField(35)
  final bool backupVialsRequiresRefrigeration;
  
  @HiveField(36)
  final bool backupVialsRequiresFreezer;
  
  @HiveField(37)
  final bool backupVialsLightSensitive;

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
    DateTime? reconstitutedAt,
    DateTime? reconstitutedVialExpiry,
    double? activeVialLowStockMl,
    String? activeVialBatchNumber,
    String? activeVialStorageLocation,
    bool? activeVialRequiresRefrigeration,
    bool? activeVialRequiresFreezer,
    bool? activeVialLightSensitive,
    DateTime? backupVialsExpiry,
    String? backupVialsBatchNumber,
    String? backupVialsStorageLocation,
    bool? backupVialsRequiresRefrigeration,
    bool? backupVialsRequiresFreezer,
    bool? backupVialsLightSensitive,
    bool clearReconstitution = false,
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
      reconstitutedAt: clearReconstitution
          ? null
          : (reconstitutedAt ?? this.reconstitutedAt),
      reconstitutedVialExpiry: clearReconstitution
          ? null
          : (reconstitutedVialExpiry ?? this.reconstitutedVialExpiry),
      activeVialLowStockMl: activeVialLowStockMl ?? this.activeVialLowStockMl,
      activeVialBatchNumber: activeVialBatchNumber ?? this.activeVialBatchNumber,
      activeVialStorageLocation: activeVialStorageLocation ?? this.activeVialStorageLocation,
      activeVialRequiresRefrigeration: activeVialRequiresRefrigeration ?? this.activeVialRequiresRefrigeration,
      activeVialRequiresFreezer: activeVialRequiresFreezer ?? this.activeVialRequiresFreezer,
      activeVialLightSensitive: activeVialLightSensitive ?? this.activeVialLightSensitive,
      backupVialsExpiry: backupVialsExpiry ?? this.backupVialsExpiry,
      backupVialsBatchNumber: backupVialsBatchNumber ?? this.backupVialsBatchNumber,
      backupVialsStorageLocation: backupVialsStorageLocation ?? this.backupVialsStorageLocation,
      backupVialsRequiresRefrigeration: backupVialsRequiresRefrigeration ?? this.backupVialsRequiresRefrigeration,
      backupVialsRequiresFreezer: backupVialsRequiresFreezer ?? this.backupVialsRequiresFreezer,
      backupVialsLightSensitive: backupVialsLightSensitive ?? this.backupVialsLightSensitive,
    );
  }
}
