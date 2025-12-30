// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

class DoseStatusChangeLog {
  const DoseStatusChangeLog({
    required this.id,
    required this.scheduleId,
    required this.scheduleName,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.changeTime,
    required this.fromStatus,
    required this.toStatus,
    this.notes,
  });

  final String id;
  final String scheduleId;
  final String scheduleName;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime;
  final DateTime changeTime;
  final String fromStatus;
  final String toStatus;
  final String? notes;
}

class DoseStatusChangeLogAdapter extends TypeAdapter<DoseStatusChangeLog> {
  @override
  int get typeId => 45;

  @override
  DoseStatusChangeLog read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }

    return DoseStatusChangeLog(
      id: fields[0] as String,
      scheduleId: fields[1] as String,
      scheduleName: fields[2] as String,
      medicationId: fields[3] as String,
      medicationName: fields[4] as String,
      scheduledTime: fields[5] as DateTime,
      changeTime: fields[6] as DateTime,
      fromStatus: fields[7] as String,
      toStatus: fields[8] as String,
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DoseStatusChangeLog obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.changeTime)
      ..writeByte(7)
      ..write(obj.fromStatus)
      ..writeByte(8)
      ..write(obj.toStatus)
      ..writeByte(9)
      ..write(obj.notes);
  }
}
