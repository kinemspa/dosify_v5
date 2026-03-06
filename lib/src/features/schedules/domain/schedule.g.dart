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
      entryValue: fields[3] as double,
      entryUnit: fields[4] as String,
      minutesOfDay: fields[5] as int,
      daysOfWeek: (fields[6] as List).cast<int>(),
      minutesOfDayUtc: fields[9] as int?,
      daysOfWeekUtc: (fields[10] as List?)?.cast<int>(),
      medicationId: fields[11] as String?,
      active: fields[7] as bool,
      pausedUntil: fields[30] as DateTime?,
      timesOfDay: (fields[12] as List?)?.cast<int>(),
      timesOfDayUtc: (fields[13] as List?)?.cast<int>(),
      cycleEveryNDays: fields[14] as int?,
      cycleAnchorDate: fields[15] as DateTime?,
      daysOfMonth: (fields[26] as List?)?.cast<int>(),
      entryUnitCode: fields[16] as int?,
      entryMassMcg: fields[17] as int?,
      entryVolumeMicroliter: fields[18] as int?,
      entryTabletQuarters: fields[19] as int?,
      entryCapsules: fields[20] as int?,
      entrySyringes: fields[21] as int?,
      entryVials: fields[22] as int?,
      entryIU: fields[23] as int?,
      displayUnitCode: fields[24] as int?,
      inputModeCode: fields[25] as int?,
      startAt: fields[27] as DateTime?,
      endAt: fields[28] as DateTime?,
      monthlyMissingDayBehaviorCode: fields[29] as int?,
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Schedule obj) {
    writer
      ..writeByte(31)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.medicationName)
      ..writeByte(3)
      ..write(obj.entryValue)
      ..writeByte(4)
      ..write(obj.entryUnit)
      ..writeByte(5)
      ..write(obj.minutesOfDay)
      ..writeByte(6)
      ..write(obj.daysOfWeek)
      ..writeByte(7)
      ..write(obj.active)
      ..writeByte(30)
      ..write(obj.pausedUntil)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(27)
      ..write(obj.startAt)
      ..writeByte(28)
      ..write(obj.endAt)
      ..writeByte(29)
      ..write(obj.monthlyMissingDayBehaviorCode)
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
      ..write(obj.entryUnitCode)
      ..writeByte(17)
      ..write(obj.entryMassMcg)
      ..writeByte(18)
      ..write(obj.entryVolumeMicroliter)
      ..writeByte(19)
      ..write(obj.entryTabletQuarters)
      ..writeByte(20)
      ..write(obj.entryCapsules)
      ..writeByte(21)
      ..write(obj.entrySyringes)
      ..writeByte(22)
      ..write(obj.entryVials)
      ..writeByte(23)
      ..write(obj.entryIU)
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
