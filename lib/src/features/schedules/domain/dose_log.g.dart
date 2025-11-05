// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dose_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DoseLogAdapter extends TypeAdapter<DoseLog> {
  @override
  final int typeId = 41;

  @override
  DoseLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoseLog(
      id: fields[0] as String,
      scheduleId: fields[1] as String,
      scheduleName: fields[2] as String,
      medicationId: fields[3] as String,
      medicationName: fields[4] as String,
      scheduledTime: fields[5] as DateTime,
      doseValue: fields[7] as double,
      doseUnit: fields[8] as String,
      action: fields[9] as DoseAction,
      actualDoseValue: fields[10] as double?,
      actualDoseUnit: fields[11] as String?,
      notes: fields[12] as String?,
      actionTime: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DoseLog obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scheduleId)
      ..writeByte(2)
      ..write(obj.scheduleName)
      ..writeByte(3)
      ..write(obj.medicationId)
      ..writeByte(4)
      ..write(obj.medicationName)
      ..writeByte(5)
      ..write(obj.scheduledTime)
      ..writeByte(6)
      ..write(obj.actionTime)
      ..writeByte(7)
      ..write(obj.doseValue)
      ..writeByte(8)
      ..write(obj.doseUnit)
      ..writeByte(9)
      ..write(obj.action)
      ..writeByte(10)
      ..write(obj.actualDoseValue)
      ..writeByte(11)
      ..write(obj.actualDoseUnit)
      ..writeByte(12)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DoseActionAdapter extends TypeAdapter<DoseAction> {
  @override
  final int typeId = 42;

  @override
  DoseAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DoseAction.taken;
      case 1:
        return DoseAction.skipped;
      case 2:
        return DoseAction.snoozed;
      default:
        return DoseAction.taken;
    }
  }

  @override
  void write(BinaryWriter writer, DoseAction obj) {
    switch (obj) {
      case DoseAction.taken:
        writer.writeByte(0);
        break;
      case DoseAction.skipped:
        writer.writeByte(1);
        break;
      case DoseAction.snoozed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
