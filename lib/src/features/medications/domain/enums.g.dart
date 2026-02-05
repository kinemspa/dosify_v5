// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnitAdapter extends TypeAdapter<Unit> {
  @override
  final int typeId = 1;

  @override
  Unit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Unit.mcg;
      case 1:
        return Unit.mg;
      case 2:
        return Unit.g;
      case 3:
        return Unit.units;
      case 4:
        return Unit.mcgPerMl;
      case 5:
        return Unit.mgPerMl;
      case 6:
        return Unit.gPerMl;
      case 7:
        return Unit.unitsPerMl;
      default:
        return Unit.mcg;
    }
  }

  @override
  void write(BinaryWriter writer, Unit obj) {
    switch (obj) {
      case Unit.mcg:
        writer.writeByte(0);
        break;
      case Unit.mg:
        writer.writeByte(1);
        break;
      case Unit.g:
        writer.writeByte(2);
        break;
      case Unit.units:
        writer.writeByte(3);
        break;
      case Unit.mcgPerMl:
        writer.writeByte(4);
        break;
      case Unit.mgPerMl:
        writer.writeByte(5);
        break;
      case Unit.gPerMl:
        writer.writeByte(6);
        break;
      case Unit.unitsPerMl:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockUnitAdapter extends TypeAdapter<StockUnit> {
  @override
  final int typeId = 2;

  @override
  StockUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StockUnit.tablets;
      case 1:
        return StockUnit.capsules;
      case 2:
        return StockUnit.preFilledSyringes;
      case 3:
        return StockUnit.singleDoseVials;
      case 4:
        return StockUnit.multiDoseVials;
      case 5:
        return StockUnit.mcg;
      case 6:
        return StockUnit.mg;
      case 7:
        return StockUnit.g;
      default:
        return StockUnit.tablets;
    }
  }

  @override
  void write(BinaryWriter writer, StockUnit obj) {
    switch (obj) {
      case StockUnit.tablets:
        writer.writeByte(0);
        break;
      case StockUnit.capsules:
        writer.writeByte(1);
        break;
      case StockUnit.preFilledSyringes:
        writer.writeByte(2);
        break;
      case StockUnit.singleDoseVials:
        writer.writeByte(3);
        break;
      case StockUnit.multiDoseVials:
        writer.writeByte(4);
        break;
      case StockUnit.mcg:
        writer.writeByte(5);
        break;
      case StockUnit.mg:
        writer.writeByte(6);
        break;
      case StockUnit.g:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedicationFormAdapter extends TypeAdapter<MedicationForm> {
  @override
  final int typeId = 3;

  @override
  MedicationForm read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MedicationForm.tablet;
      case 1:
        return MedicationForm.capsule;
      case 2:
        return MedicationForm.prefilledSyringe;
      case 3:
        return MedicationForm.singleDoseVial;
      case 4:
        return MedicationForm.multiDoseVial;
      default:
        return MedicationForm.tablet;
    }
  }

  @override
  void write(BinaryWriter writer, MedicationForm obj) {
    switch (obj) {
      case MedicationForm.tablet:
        writer.writeByte(0);
        break;
      case MedicationForm.capsule:
        writer.writeByte(1);
        break;
      case MedicationForm.prefilledSyringe:
        writer.writeByte(2);
        break;
      case MedicationForm.singleDoseVial:
        writer.writeByte(3);
        break;
      case MedicationForm.multiDoseVial:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationFormAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VolumeUnitAdapter extends TypeAdapter<VolumeUnit> {
  @override
  final int typeId = 4;

  @override
  VolumeUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VolumeUnit.ml;
      case 1:
        return VolumeUnit.l;
      default:
        return VolumeUnit.ml;
    }
  }

  @override
  void write(BinaryWriter writer, VolumeUnit obj) {
    switch (obj) {
      case VolumeUnit.ml:
        writer.writeByte(0);
        break;
      case VolumeUnit.l:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumeUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
