// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sealed_vial_batch.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SealedVialBatchAdapter extends TypeAdapter<SealedVialBatch> {
  @override
  final int typeId = 61;

  @override
  SealedVialBatch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SealedVialBatch(
      count: fields[1] as int,
      name: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SealedVialBatch obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SealedVialBatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
