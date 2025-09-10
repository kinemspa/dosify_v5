import 'package:hive_flutter/hive_flutter.dart';

part 'supply.g.dart';

@HiveType(typeId: 52)
enum SupplyType {
  @HiveField(0)
  item,
  @HiveField(1)
  fluid,
}

@HiveType(typeId: 53)
enum SupplyUnit {
  @HiveField(0)
  pcs,
  @HiveField(1)
  ml,
  @HiveField(2)
  l,
}

@HiveType(typeId: 50)
class Supply {
  Supply({
    required this.id,
    required this.name,
    required this.type,
    this.category,
    required this.unit,
    this.reorderThreshold,
    this.expiry,
    this.storageLocation,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  final String id; // uuid
  @HiveField(1)
  final String name;
  @HiveField(2)
  final SupplyType type;
  @HiveField(3)
  final String? category; // e.g., needles, swabs, pen tips
  @HiveField(4)
  final SupplyUnit unit; // pcs/ml/l
  @HiveField(5)
  final double? reorderThreshold; // same unit as unit
  @HiveField(6)
  final DateTime? expiry;
  @HiveField(7)
  final String? storageLocation;
  @HiveField(8)
  final String? notes;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  final DateTime updatedAt;

  Supply copyWith({
    String? id,
    String? name,
    SupplyType? type,
    String? category,
    SupplyUnit? unit,
    double? reorderThreshold,
    DateTime? expiry,
    String? storageLocation,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supply(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      reorderThreshold: reorderThreshold ?? this.reorderThreshold,
      expiry: expiry ?? this.expiry,
      storageLocation: storageLocation ?? this.storageLocation,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

