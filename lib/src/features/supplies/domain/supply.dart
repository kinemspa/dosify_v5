// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 52)
enum SupplyType {
  @HiveField(0)
  item,
  @HiveField(1)
  fluid,
}

class SupplyTypeAdapter extends TypeAdapter<SupplyType> {
  @override
  final int typeId = 52;

  @override
  SupplyType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SupplyType.item;
      case 1:
        return SupplyType.fluid;
      default:
        return SupplyType.item;
    }
  }

  @override
  void write(BinaryWriter writer, SupplyType obj) {
    switch (obj) {
      case SupplyType.item:
        writer.writeByte(0);
      case SupplyType.fluid:
        writer.writeByte(1);
    }
  }
}

class SupplyUnitAdapter extends TypeAdapter<SupplyUnit> {
  @override
  final int typeId = 53;

  @override
  SupplyUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SupplyUnit.pcs;
      case 1:
        return SupplyUnit.ml;
      case 2:
        return SupplyUnit.l;
      default:
        return SupplyUnit.pcs;
    }
  }

  @override
  void write(BinaryWriter writer, SupplyUnit obj) {
    switch (obj) {
      case SupplyUnit.pcs:
        writer.writeByte(0);
      case SupplyUnit.ml:
        writer.writeByte(1);
      case SupplyUnit.l:
        writer.writeByte(2);
    }
  }
}

class SupplyAdapter extends TypeAdapter<Supply> {
  @override
  final int typeId = 50;

  @override
  Supply read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Supply(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as SupplyType,
      category: fields[3] as String?,
      unit: fields[4] as SupplyUnit,
      reorderThreshold: fields[5] as double?,
      expiry: fields[6] as DateTime?,
      storageLocation: fields[7] as String?,
      notes: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Supply obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.reorderThreshold)
      ..writeByte(6)
      ..write(obj.expiry)
      ..writeByte(7)
      ..write(obj.storageLocation)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }
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
    required this.unit, this.category,
    this.reorderThreshold,
    this.expiry,
    this.storageLocation,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
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
