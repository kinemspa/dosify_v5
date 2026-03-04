// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntryLogAdapter extends TypeAdapter<EntryLog> {
  @override
  final int typeId = 41;

  @override
  EntryLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EntryLog(
      id: fields[0] as String,
      scheduleId: fields[1] as String,
      scheduleName: fields[2] as String,
      medicationId: fields[3] as String,
      medicationName: fields[4] as String,
      scheduledTime: fields[5] as DateTime,
      entryValue: fields[7] as double,
      entryUnit: fields[8] as String,
      action: fields[9] as EntryAction,
      actualEntryValue: fields[10] as double?,
      actualEntryUnit: fields[11] as String?,
      notes: fields[12] as String?,
      actionTime: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EntryLog obj) {
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
      ..write(obj.entryValue)
      ..writeByte(8)
      ..write(obj.entryUnit)
      ..writeByte(9)
      ..write(obj.action)
      ..writeByte(10)
      ..write(obj.actualEntryValue)
      ..writeByte(11)
      ..write(obj.actualEntryUnit)
      ..writeByte(12)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EntryActionAdapter extends TypeAdapter<EntryAction> {
  @override
  final int typeId = 42;

  @override
  EntryAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EntryAction.logged;
      case 1:
        return EntryAction.skipped;
      case 2:
        return EntryAction.snoozed;
      default:
        return EntryAction.logged;
    }
  }

  @override
  void write(BinaryWriter writer, EntryAction obj) {
    switch (obj) {
      case EntryAction.logged:
        writer.writeByte(0);
        break;
      case EntryAction.skipped:
        writer.writeByte(1);
        break;
      case EntryAction.snoozed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
