// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryLogAdapter extends TypeAdapter<InventoryLog> {
  @override
  final int typeId = 43;

  @override
  InventoryLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryLog(
      id: fields[0] as String,
      medicationId: fields[1] as String,
      medicationName: fields[2] as String,
      changeType: fields[4] as InventoryChangeType,
      previousStock: fields[5] as double,
      newStock: fields[6] as double,
      changeAmount: fields[7] as double,
      notes: fields[8] as String?,
      timestamp: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicationId)
      ..writeByte(2)
      ..write(obj.medicationName)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.changeType)
      ..writeByte(5)
      ..write(obj.previousStock)
      ..writeByte(6)
      ..write(obj.newStock)
      ..writeByte(7)
      ..write(obj.changeAmount)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InventoryChangeTypeAdapter extends TypeAdapter<InventoryChangeType> {
  @override
  final int typeId = 44;

  @override
  InventoryChangeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InventoryChangeType.refillAdd;
      case 1:
        return InventoryChangeType.refillToMax;
      case 2:
        return InventoryChangeType.doseDeducted;
      case 3:
        return InventoryChangeType.adHocDose;
      case 4:
        return InventoryChangeType.manualAdjustment;
      case 5:
        return InventoryChangeType.vialOpened;
      case 6:
        return InventoryChangeType.vialRestocked;
      case 7:
        return InventoryChangeType.expired;
      default:
        return InventoryChangeType.refillAdd;
    }
  }

  @override
  void write(BinaryWriter writer, InventoryChangeType obj) {
    switch (obj) {
      case InventoryChangeType.refillAdd:
        writer.writeByte(0);
        break;
      case InventoryChangeType.refillToMax:
        writer.writeByte(1);
        break;
      case InventoryChangeType.doseDeducted:
        writer.writeByte(2);
        break;
      case InventoryChangeType.adHocDose:
        writer.writeByte(3);
        break;
      case InventoryChangeType.manualAdjustment:
        writer.writeByte(4);
        break;
      case InventoryChangeType.vialOpened:
        writer.writeByte(5);
        break;
      case InventoryChangeType.vialRestocked:
        writer.writeByte(6);
        break;
      case InventoryChangeType.expired:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryChangeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
