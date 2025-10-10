// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleAdapter extends TypeAdapter<Schedule> {
  @override
  final int typeId = 40;

  @override
  Schedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Schedule(
      id: fields[0] as String,
      name: fields[1] as String,
      medicationName: fields[2] as String,
      doseValue: fields[3] as double,
      doseUnit: fields[4] as String,
      minutesOfDay: fields[5] as int,
      daysOfWeek: (fields[6] as List).cast<int>(),
      minutesOfDayUtc: fields[9] as int?,
      daysOfWeekUtc: (fields[10] as List?)?.cast<int>(),
      medicationId: fields[11] as String?,
      active: fields[7] as bool,
      timesOfDay: (fields[12] as List?)?.cast<int>(),
      timesOfDayUtc: (fields[13] as List?)?.cast<int>(),
      cycleEveryNDays: fields[14] as int?,
      cycleAnchorDate: fields[15] as DateTime?,
      daysOfMonth: (fields[26] as List?)?.cast<int>(),
      doseUnitCode: fields[16] as int?,
      doseMassMcg: fields[17] as int?,
      doseVolumeMicroliter: fields[18] as int?,
      doseTabletQuarters: fields[19] as int?,
      doseCapsules: fields[20] as int?,
      doseSyringes: fields[21] as int?,
      doseVials: fields[22] as int?,
      doseIU: fields[23] as int?,
      displayUnitCode: fields[24] as int?,
      inputModeCode: fields[25] as int?,
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Schedule obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.medicationName)
      ..writeByte(3)
      ..write(obj.doseValue)
      ..writeByte(4)
      ..write(obj.doseUnit)
      ..writeByte(5)
      ..write(obj.minutesOfDay)
      ..writeByte(6)
      ..write(obj.daysOfWeek)
      ..writeByte(7)
      ..write(obj.active)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.minutesOfDayUtc)
      ..writeByte(10)
      ..write(obj.daysOfWeekUtc)
      ..writeByte(11)
      ..write(obj.medicationId)
      ..writeByte(12)
      ..write(obj.timesOfDay)
      ..writeByte(13)
      ..write(obj.timesOfDayUtc)
      ..writeByte(14)
      ..write(obj.cycleEveryNDays)
      ..writeByte(15)
      ..write(obj.cycleAnchorDate)
      ..writeByte(26)
      ..write(obj.daysOfMonth)
      ..writeByte(16)
      ..write(obj.doseUnitCode)
      ..writeByte(17)
      ..write(obj.doseMassMcg)
      ..writeByte(18)
      ..write(obj.doseVolumeMicroliter)
      ..writeByte(19)
      ..write(obj.doseTabletQuarters)
      ..writeByte(20)
      ..write(obj.doseCapsules)
      ..writeByte(21)
      ..write(obj.doseSyringes)
      ..writeByte(22)
      ..write(obj.doseVials)
      ..writeByte(23)
      ..write(obj.doseIU)
      ..writeByte(24)
      ..write(obj.displayUnitCode)
      ..writeByte(25)
      ..write(obj.inputModeCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
