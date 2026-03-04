// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

part 'inventory_log.g.dart';

/// Records stock changes for medications (refills, adjustments, usage).
/// Persists even if medication is deleted for historical reporting.
@HiveType(typeId: 43)
class InventoryLog {
  InventoryLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.changeType,
    required this.previousStock,
    required this.newStock,
    required this.changeAmount,
    this.notes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @HiveField(0)
  final String id; // uuid

  @HiveField(1)
  final String medicationId; // Reference to medication (may be deleted)

  @HiveField(2)
  final String medicationName; // Stored name for historical reporting

  @HiveField(3)
  final DateTime timestamp; // When the change occurred (UTC)

  @HiveField(4)
  final InventoryChangeType changeType; // Type of stock change

  @HiveField(5)
  final double previousStock; // Stock before change

  @HiveField(6)
  final double newStock; // Stock after change

  @HiveField(7)
  final double changeAmount; // Amount changed (positive for add, negative for deduct)

  @HiveField(8)
  final String? notes; // Optional notes (e.g., "Refilled to max", prescription number)

  /// Whether this log references a deleted medication
  bool isOrphanedMedication(List<String> activeMedicationIds) {
    return !activeMedicationIds.contains(medicationId);
  }

  /// Human-readable description of the change
  String get description {
    switch (changeType) {
      case InventoryChangeType.refillAdd:
        return 'Added ${changeAmount.abs().toStringAsFixed(changeAmount.abs() == changeAmount.abs().roundToDouble() ? 0 : 1)} to stock';
      case InventoryChangeType.refillToMax:
        return 'Refilled to maximum (${newStock.toStringAsFixed(newStock == newStock.roundToDouble() ? 0 : 1)})';
      case InventoryChangeType.entryDeducted:
        return 'Entry taken (${changeAmount.abs().toStringAsFixed(changeAmount.abs() == changeAmount.abs().roundToDouble() ? 0 : 1)} deducted)';
      case InventoryChangeType.adHocEntry:
        return 'Ad-hoc entry (${changeAmount.abs().toStringAsFixed(changeAmount.abs() == changeAmount.abs().roundToDouble() ? 0 : 1)} deducted)';
      case InventoryChangeType.manualAdjustment:
        return 'Manual adjustment';
      case InventoryChangeType.vialOpened:
        return 'New vial opened';
      case InventoryChangeType.vialRestocked:
        return 'Sealed vials restocked';
      case InventoryChangeType.expired:
        return 'Expired stock removed';
    }
  }
}

@HiveType(typeId: 44)
enum InventoryChangeType {
  @HiveField(0)
  refillAdd, // Added specific amount to stock

  @HiveField(1)
  refillToMax, // Refilled to maximum stock level

  @HiveField(2)
  entryDeducted, // Scheduled entry deducted stock

  @HiveField(3)
  adHocEntry, // Ad-hoc entry deducted stock

  @HiveField(4)
  manualAdjustment, // Manual stock correction

  @HiveField(5)
  vialOpened, // MDV: opened new vial

  @HiveField(6)
  vialRestocked, // MDV: added sealed vials to reserve

  @HiveField(7)
  expired, // Expired stock removed
}
