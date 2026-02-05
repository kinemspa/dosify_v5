// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 10;

  @override
  Medication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medication(
      id: fields[0] as String,
      form: fields[1] as MedicationForm,
      name: fields[2] as String,
      strengthValue: fields[6] as double,
      strengthUnit: fields[7] as Unit,
      stockValue: fields[9] as double,
      stockUnit: fields[10] as StockUnit,
      manufacturer: fields[3] as String?,
      description: fields[4] as String?,
      notes: fields[5] as String?,
      perMlValue: fields[8] as double?,
      volumePerDose: fields[38] as double?,
      volumeUnit: fields[39] as VolumeUnit?,
      lowStockEnabled: fields[11] as bool,
      lowStockThreshold: fields[12] as double?,
      expiry: fields[13] as DateTime?,
      batchNumber: fields[14] as String?,
      storageLocation: fields[15] as String?,
      requiresRefrigeration: fields[16] as bool,
      requiresFreezer: fields[42] as bool,
      lightSensitive: fields[43] as bool,
      storageInstructions: fields[17] as String?,
      createdAt: fields[18] as DateTime?,
      updatedAt: fields[19] as DateTime?,
      containerVolumeMl: fields[20] as double?,
      lowStockVialVolumeThresholdMl: fields[21] as double?,
      lowStockVialsThresholdCount: fields[22] as double?,
      initialStockValue: fields[23] as double?,
      reconstitutedAt: fields[24] as DateTime?,
      reconstitutedVialExpiry: fields[25] as DateTime?,
      activeVialLowStockMl: fields[26] as double?,
      activeVialBatchNumber: fields[27] as String?,
      activeVialStorageLocation: fields[28] as String?,
      activeVialRequiresRefrigeration: fields[29] as bool,
      activeVialRequiresFreezer: fields[30] as bool,
      activeVialLightSensitive: fields[31] as bool,
      backupVialsExpiry: fields[32] as DateTime?,
      backupVialsBatchNumber: fields[33] as String?,
      backupVialsStorageLocation: fields[34] as String?,
      backupVialsRequiresRefrigeration: fields[35] as bool,
      backupVialsRequiresFreezer: fields[36] as bool,
      backupVialsLightSensitive: fields[37] as bool,
      activeVialVolume: fields[40] as double?,
      diluentName: fields[41] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(44)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.form)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.manufacturer)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.strengthValue)
      ..writeByte(7)
      ..write(obj.strengthUnit)
      ..writeByte(8)
      ..write(obj.perMlValue)
      ..writeByte(38)
      ..write(obj.volumePerDose)
      ..writeByte(39)
      ..write(obj.volumeUnit)
      ..writeByte(40)
      ..write(obj.activeVialVolume)
      ..writeByte(41)
      ..write(obj.diluentName)
      ..writeByte(9)
      ..write(obj.stockValue)
      ..writeByte(10)
      ..write(obj.stockUnit)
      ..writeByte(11)
      ..write(obj.lowStockEnabled)
      ..writeByte(12)
      ..write(obj.lowStockThreshold)
      ..writeByte(13)
      ..write(obj.expiry)
      ..writeByte(14)
      ..write(obj.batchNumber)
      ..writeByte(15)
      ..write(obj.storageLocation)
      ..writeByte(16)
      ..write(obj.requiresRefrigeration)
      ..writeByte(42)
      ..write(obj.requiresFreezer)
      ..writeByte(43)
      ..write(obj.lightSensitive)
      ..writeByte(17)
      ..write(obj.storageInstructions)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.updatedAt)
      ..writeByte(20)
      ..write(obj.containerVolumeMl)
      ..writeByte(21)
      ..write(obj.lowStockVialVolumeThresholdMl)
      ..writeByte(22)
      ..write(obj.lowStockVialsThresholdCount)
      ..writeByte(23)
      ..write(obj.initialStockValue)
      ..writeByte(24)
      ..write(obj.reconstitutedAt)
      ..writeByte(25)
      ..write(obj.reconstitutedVialExpiry)
      ..writeByte(26)
      ..write(obj.activeVialLowStockMl)
      ..writeByte(27)
      ..write(obj.activeVialBatchNumber)
      ..writeByte(28)
      ..write(obj.activeVialStorageLocation)
      ..writeByte(29)
      ..write(obj.activeVialRequiresRefrigeration)
      ..writeByte(30)
      ..write(obj.activeVialRequiresFreezer)
      ..writeByte(31)
      ..write(obj.activeVialLightSensitive)
      ..writeByte(32)
      ..write(obj.backupVialsExpiry)
      ..writeByte(33)
      ..write(obj.backupVialsBatchNumber)
      ..writeByte(34)
      ..write(obj.backupVialsStorageLocation)
      ..writeByte(35)
      ..write(obj.backupVialsRequiresRefrigeration)
      ..writeByte(36)
      ..write(obj.backupVialsRequiresFreezer)
      ..writeByte(37)
      ..write(obj.backupVialsLightSensitive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
