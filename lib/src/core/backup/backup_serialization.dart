import 'dart:convert';

import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/inventory_log.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:skedux/src/features/medications/domain/sealed_vial_batch.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/entry_status_change_log.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/supplies/domain/stock_movement.dart';
import 'package:skedux/src/features/supplies/domain/supply.dart';

class BackupBoxRecord {
  const BackupBoxRecord({required this.key, required this.value});

  final Object? key;
  final Map<String, Object?> value;

  Map<String, Object?> toJson() => {'key': key, 'value': value};

  factory BackupBoxRecord.fromJson(Map<String, Object?> json) {
    final value = json['value'];
    if (value is! Map) {
      throw const FormatException('Invalid backup record value');
    }
    return BackupBoxRecord(
      key: json['key'],
      value: Map<String, Object?>.from(value),
    );
  }
}

List<int> encodeBackupRecords(List<BackupBoxRecord> records) {
  final payload = records.map((record) => record.toJson()).toList(growable: false);
  return utf8.encode(const JsonEncoder.withIndent('  ').convert(payload));
}

List<BackupBoxRecord> decodeBackupRecords(List<int> bytes) {
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! List) {
    throw const FormatException('Invalid backup records payload');
  }
  return decoded
      .map((entry) => BackupBoxRecord.fromJson(Map<String, Object?>.from(entry as Map)))
      .toList(growable: false);
}

List<BackupBoxRecord> serializeBoxRecords(String boxName, Map<dynamic, dynamic> values) {
  return values.entries
      .map(
        (entry) => BackupBoxRecord(
          key: entry.key,
          value: serializeValue(boxName, entry.value),
        ),
      )
      .toList(growable: false);
}

MapEntry<dynamic, dynamic> deserializeBoxRecord(String boxName, BackupBoxRecord record) {
  return MapEntry(record.key, deserializeValue(boxName, record.value));
}

Map<String, Object?> serializeValue(String boxName, Object? value) {
  return switch (boxName) {
    'medications' => _serializeMedication(value as Medication),
    'schedules' => _serializeSchedule(value as Schedule),
    'entry_logs' => _serializeEntryLog(value as EntryLog),
    'entry_status_change_logs' => _serializeEntryStatusChangeLog(value as EntryStatusChangeLog),
    'supplies' => _serializeSupply(value as Supply),
    'stock_movements' => _serializeStockMovement(value as StockMovement),
    'inventory_logs' => _serializeInventoryLog(value as InventoryLog),
    'saved_reconstitutions' => _serializeSavedReconstitution(value as SavedReconstitutionCalculation),
    _ => throw ArgumentError.value(boxName, 'boxName', 'Unsupported backup box'),
  };
}

Object deserializeValue(String boxName, Map<String, Object?> json) {
  return switch (boxName) {
    'medications' => _deserializeMedication(json),
    'schedules' => _deserializeSchedule(json),
    'entry_logs' => _deserializeEntryLog(json),
    'entry_status_change_logs' => _deserializeEntryStatusChangeLog(json),
    'supplies' => _deserializeSupply(json),
    'stock_movements' => _deserializeStockMovement(json),
    'inventory_logs' => _deserializeInventoryLog(json),
    'saved_reconstitutions' => _deserializeSavedReconstitution(json),
    _ => throw ArgumentError.value(boxName, 'boxName', 'Unsupported backup box'),
  };
}

Map<String, Object?> _serializeMedication(Medication value) => {
      'id': value.id,
      'form': value.form.name,
      'name': value.name,
      'manufacturer': value.manufacturer,
      'description': value.description,
      'notes': value.notes,
      'strengthValue': value.strengthValue,
      'strengthUnit': value.strengthUnit.name,
      'perMlValue': value.perMlValue,
      'volumePerEntry': value.volumePerEntry,
      'volumeUnit': value.volumeUnit?.name,
      'activeVialVolume': value.activeVialVolume,
      'diluentName': value.diluentName,
      'stockValue': value.stockValue,
      'stockUnit': value.stockUnit.name,
      'lowStockEnabled': value.lowStockEnabled,
      'lowStockThreshold': value.lowStockThreshold,
      'expiry': _date(value.expiry),
      'batchNumber': value.batchNumber,
      'storageLocation': value.storageLocation,
      'requiresRefrigeration': value.requiresRefrigeration,
      'requiresFreezer': value.requiresFreezer,
      'lightSensitive': value.lightSensitive,
      'storageInstructions': value.storageInstructions,
      'createdAt': _date(value.createdAt),
      'updatedAt': _date(value.updatedAt),
      'containerVolumeMl': value.containerVolumeMl,
      'lowStockVialVolumeThresholdMl': value.lowStockVialVolumeThresholdMl,
      'lowStockVialsThresholdCount': value.lowStockVialsThresholdCount,
      'initialStockValue': value.initialStockValue,
      'reconstitutedAt': _date(value.reconstitutedAt),
      'reconstitutedVialExpiry': _date(value.reconstitutedVialExpiry),
      'activeVialLowStockMl': value.activeVialLowStockMl,
      'activeVialBatchNumber': value.activeVialBatchNumber,
      'activeVialStorageLocation': value.activeVialStorageLocation,
      'activeVialRequiresRefrigeration': value.activeVialRequiresRefrigeration,
      'activeVialRequiresFreezer': value.activeVialRequiresFreezer,
      'activeVialLightSensitive': value.activeVialLightSensitive,
      'backupVialsExpiry': _date(value.backupVialsExpiry),
      'backupVialsBatchNumber': value.backupVialsBatchNumber,
      'backupVialsStorageLocation': value.backupVialsStorageLocation,
      'backupVialsRequiresRefrigeration': value.backupVialsRequiresRefrigeration,
      'backupVialsRequiresFreezer': value.backupVialsRequiresFreezer,
      'backupVialsLightSensitive': value.backupVialsLightSensitive,
      'sealedVialBatches': value.sealedVialBatches
          ?.map((batch) => _serializeSealedVialBatch(batch))
          .toList(growable: false),
    };

Medication _deserializeMedication(Map<String, Object?> json) => Medication(
      id: _str(json, 'id'),
      form: MedicationForm.values.byName(_str(json, 'form')),
      name: _str(json, 'name'),
      strengthValue: _dbl(json, 'strengthValue'),
      strengthUnit: Unit.values.byName(_str(json, 'strengthUnit')),
      stockValue: _dbl(json, 'stockValue'),
      stockUnit: StockUnit.values.byName(_str(json, 'stockUnit')),
      manufacturer: _optStr(json, 'manufacturer'),
      description: _optStr(json, 'description'),
      notes: _optStr(json, 'notes'),
      perMlValue: _optDbl(json, 'perMlValue'),
      volumePerEntry: _optDbl(json, 'volumePerEntry'),
        volumeUnit: _optVolumeUnit(json, 'volumeUnit'),
      lowStockEnabled: _bool(json, 'lowStockEnabled'),
      lowStockThreshold: _optDbl(json, 'lowStockThreshold'),
      expiry: _optDate(json, 'expiry'),
      batchNumber: _optStr(json, 'batchNumber'),
      storageLocation: _optStr(json, 'storageLocation'),
      requiresRefrigeration: _bool(json, 'requiresRefrigeration'),
      requiresFreezer: _bool(json, 'requiresFreezer'),
      lightSensitive: _bool(json, 'lightSensitive'),
      storageInstructions: _optStr(json, 'storageInstructions'),
      createdAt: _optDate(json, 'createdAt'),
      updatedAt: _optDate(json, 'updatedAt'),
      containerVolumeMl: _optDbl(json, 'containerVolumeMl'),
      lowStockVialVolumeThresholdMl: _optDbl(json, 'lowStockVialVolumeThresholdMl'),
      lowStockVialsThresholdCount: _optDbl(json, 'lowStockVialsThresholdCount'),
      initialStockValue: _optDbl(json, 'initialStockValue'),
      reconstitutedAt: _optDate(json, 'reconstitutedAt'),
      reconstitutedVialExpiry: _optDate(json, 'reconstitutedVialExpiry'),
      activeVialLowStockMl: _optDbl(json, 'activeVialLowStockMl'),
      activeVialBatchNumber: _optStr(json, 'activeVialBatchNumber'),
      activeVialStorageLocation: _optStr(json, 'activeVialStorageLocation'),
      activeVialRequiresRefrigeration: _bool(json, 'activeVialRequiresRefrigeration'),
      activeVialRequiresFreezer: _bool(json, 'activeVialRequiresFreezer'),
      activeVialLightSensitive: _bool(json, 'activeVialLightSensitive'),
      backupVialsExpiry: _optDate(json, 'backupVialsExpiry'),
      backupVialsBatchNumber: _optStr(json, 'backupVialsBatchNumber'),
      backupVialsStorageLocation: _optStr(json, 'backupVialsStorageLocation'),
      backupVialsRequiresRefrigeration: _bool(json, 'backupVialsRequiresRefrigeration'),
      backupVialsRequiresFreezer: _bool(json, 'backupVialsRequiresFreezer'),
      backupVialsLightSensitive: _bool(json, 'backupVialsLightSensitive'),
      activeVialVolume: _optDbl(json, 'activeVialVolume'),
      diluentName: _optStr(json, 'diluentName'),
      sealedVialBatches: _optList(json, 'sealedVialBatches')
          ?.map((entry) => _deserializeSealedVialBatch(Map<String, Object?>.from(entry as Map)))
          .toList(growable: false),
    );

Map<String, Object?> _serializeSchedule(Schedule value) => {
      'id': value.id,
      'name': value.name,
      'medicationName': value.medicationName,
      'entryValue': value.entryValue,
      'entryUnit': value.entryUnit,
      'minutesOfDay': value.minutesOfDay,
      'daysOfWeek': value.daysOfWeek,
      'minutesOfDayUtc': value.minutesOfDayUtc,
      'daysOfWeekUtc': value.daysOfWeekUtc,
      'medicationId': value.medicationId,
      'active': value.active,
      'pausedUntil': _date(value.pausedUntil),
      'timesOfDay': value.timesOfDay,
      'timesOfDayUtc': value.timesOfDayUtc,
      'cycleEveryNDays': value.cycleEveryNDays,
      'cycleAnchorDate': _date(value.cycleAnchorDate),
      'daysOfMonth': value.daysOfMonth,
      'entryUnitCode': value.entryUnitCode,
      'entryMassMcg': value.entryMassMcg,
      'entryVolumeMicroliter': value.entryVolumeMicroliter,
      'entryTabletQuarters': value.entryTabletQuarters,
      'entryCapsules': value.entryCapsules,
      'entrySyringes': value.entrySyringes,
      'entryVials': value.entryVials,
      'entryIU': value.entryIU,
      'displayUnitCode': value.displayUnitCode,
      'inputModeCode': value.inputModeCode,
      'startAt': _date(value.startAt),
      'endAt': _date(value.endAt),
      'monthlyMissingDayBehaviorCode': value.monthlyMissingDayBehaviorCode,
      'createdAt': _date(value.createdAt),
    };

Schedule _deserializeSchedule(Map<String, Object?> json) => Schedule(
      id: _str(json, 'id'),
      name: _str(json, 'name'),
      medicationName: _str(json, 'medicationName'),
      entryValue: _dbl(json, 'entryValue'),
      entryUnit: _str(json, 'entryUnit'),
      minutesOfDay: _int(json, 'minutesOfDay'),
      daysOfWeek: _intList(json, 'daysOfWeek'),
      minutesOfDayUtc: _optInt(json, 'minutesOfDayUtc'),
      daysOfWeekUtc: _optIntList(json, 'daysOfWeekUtc'),
      medicationId: _optStr(json, 'medicationId'),
      active: _bool(json, 'active'),
      pausedUntil: _optDate(json, 'pausedUntil'),
      timesOfDay: _optIntList(json, 'timesOfDay'),
      timesOfDayUtc: _optIntList(json, 'timesOfDayUtc'),
      cycleEveryNDays: _optInt(json, 'cycleEveryNDays'),
      cycleAnchorDate: _optDate(json, 'cycleAnchorDate'),
      daysOfMonth: _optIntList(json, 'daysOfMonth'),
      entryUnitCode: _optInt(json, 'entryUnitCode'),
      entryMassMcg: _optInt(json, 'entryMassMcg'),
      entryVolumeMicroliter: _optInt(json, 'entryVolumeMicroliter'),
      entryTabletQuarters: _optInt(json, 'entryTabletQuarters'),
      entryCapsules: _optInt(json, 'entryCapsules'),
      entrySyringes: _optInt(json, 'entrySyringes'),
      entryVials: _optInt(json, 'entryVials'),
      entryIU: _optInt(json, 'entryIU'),
      displayUnitCode: _optInt(json, 'displayUnitCode'),
      inputModeCode: _optInt(json, 'inputModeCode'),
      startAt: _optDate(json, 'startAt'),
      endAt: _optDate(json, 'endAt'),
      monthlyMissingDayBehaviorCode: _optInt(json, 'monthlyMissingDayBehaviorCode'),
      createdAt: _optDate(json, 'createdAt'),
    );

Map<String, Object?> _serializeEntryLog(EntryLog value) => {
      'id': value.id,
      'scheduleId': value.scheduleId,
      'scheduleName': value.scheduleName,
      'medicationId': value.medicationId,
      'medicationName': value.medicationName,
      'scheduledTime': _date(value.scheduledTime),
      'actionTime': _date(value.actionTime),
      'entryValue': value.entryValue,
      'entryUnit': value.entryUnit,
      'action': value.action.name,
      'actualEntryValue': value.actualEntryValue,
      'actualEntryUnit': value.actualEntryUnit,
      'notes': value.notes,
    };

EntryLog _deserializeEntryLog(Map<String, Object?> json) => EntryLog(
      id: _str(json, 'id'),
      scheduleId: _str(json, 'scheduleId'),
      scheduleName: _str(json, 'scheduleName'),
      medicationId: _str(json, 'medicationId'),
      medicationName: _str(json, 'medicationName'),
      scheduledTime: _dateReq(json, 'scheduledTime'),
      actionTime: _optDate(json, 'actionTime'),
      entryValue: _dbl(json, 'entryValue'),
      entryUnit: _str(json, 'entryUnit'),
      action: EntryAction.values.byName(_str(json, 'action')),
      actualEntryValue: _optDbl(json, 'actualEntryValue'),
      actualEntryUnit: _optStr(json, 'actualEntryUnit'),
      notes: _optStr(json, 'notes'),
    );

Map<String, Object?> _serializeEntryStatusChangeLog(EntryStatusChangeLog value) => {
      'id': value.id,
      'scheduleId': value.scheduleId,
      'scheduleName': value.scheduleName,
      'medicationId': value.medicationId,
      'medicationName': value.medicationName,
      'scheduledTime': _date(value.scheduledTime),
      'changeTime': _date(value.changeTime),
      'fromStatus': value.fromStatus,
      'toStatus': value.toStatus,
      'notes': value.notes,
    };

EntryStatusChangeLog _deserializeEntryStatusChangeLog(Map<String, Object?> json) => EntryStatusChangeLog(
      id: _str(json, 'id'),
      scheduleId: _str(json, 'scheduleId'),
      scheduleName: _str(json, 'scheduleName'),
      medicationId: _str(json, 'medicationId'),
      medicationName: _str(json, 'medicationName'),
      scheduledTime: _dateReq(json, 'scheduledTime'),
      changeTime: _dateReq(json, 'changeTime'),
      fromStatus: _str(json, 'fromStatus'),
      toStatus: _str(json, 'toStatus'),
      notes: _optStr(json, 'notes'),
    );

Map<String, Object?> _serializeSupply(Supply value) => {
      'id': value.id,
      'name': value.name,
      'type': value.type.name,
      'category': value.category,
      'unit': value.unit.name,
      'reorderThreshold': value.reorderThreshold,
      'expiry': _date(value.expiry),
      'storageLocation': value.storageLocation,
      'notes': value.notes,
      'createdAt': _date(value.createdAt),
      'updatedAt': _date(value.updatedAt),
    };

Supply _deserializeSupply(Map<String, Object?> json) => Supply(
      id: _str(json, 'id'),
      name: _str(json, 'name'),
      type: SupplyType.values.byName(_str(json, 'type')),
      unit: SupplyUnit.values.byName(_str(json, 'unit')),
      category: _optStr(json, 'category'),
      reorderThreshold: _optDbl(json, 'reorderThreshold'),
      expiry: _optDate(json, 'expiry'),
      storageLocation: _optStr(json, 'storageLocation'),
      notes: _optStr(json, 'notes'),
      createdAt: _optDate(json, 'createdAt'),
      updatedAt: _optDate(json, 'updatedAt'),
    );

Map<String, Object?> _serializeStockMovement(StockMovement value) => {
      'id': value.id,
      'supplyId': value.supplyId,
      'delta': value.delta,
      'reason': value.reason.name,
      'note': value.note,
      'at': _date(value.at),
    };

StockMovement _deserializeStockMovement(Map<String, Object?> json) => StockMovement(
      id: _str(json, 'id'),
      supplyId: _str(json, 'supplyId'),
      delta: _dbl(json, 'delta'),
      reason: MovementReason.values.byName(_str(json, 'reason')),
      note: _optStr(json, 'note'),
      at: _optDate(json, 'at'),
    );

Map<String, Object?> _serializeInventoryLog(InventoryLog value) => {
      'id': value.id,
      'medicationId': value.medicationId,
      'medicationName': value.medicationName,
      'timestamp': _date(value.timestamp),
      'changeType': value.changeType.name,
      'previousStock': value.previousStock,
      'newStock': value.newStock,
      'changeAmount': value.changeAmount,
      'notes': value.notes,
      'batchNumber': value.batchNumber,
    };

InventoryLog _deserializeInventoryLog(Map<String, Object?> json) => InventoryLog(
      id: _str(json, 'id'),
      medicationId: _str(json, 'medicationId'),
      medicationName: _str(json, 'medicationName'),
      changeType: InventoryChangeType.values.byName(_str(json, 'changeType')),
      previousStock: _dbl(json, 'previousStock'),
      newStock: _dbl(json, 'newStock'),
      changeAmount: _dbl(json, 'changeAmount'),
      notes: _optStr(json, 'notes'),
      batchNumber: _optStr(json, 'batchNumber'),
      timestamp: _optDate(json, 'timestamp'),
    );

Map<String, Object?> _serializeSavedReconstitution(SavedReconstitutionCalculation value) => {
      'id': value.id,
      'name': value.name,
      'ownerMedicationId': value.ownerMedicationId,
      'medicationName': value.medicationName,
      'strengthValue': value.strengthValue,
      'strengthUnit': value.strengthUnit,
      'solventVolumeMl': value.solventVolumeMl,
      'perMlConcentration': value.perMlConcentration,
      'calculatedUnits': value.calculatedUnits,
      'syringeSizeMl': value.syringeSizeMl,
      'diluentName': value.diluentName,
      'calculatedEntry': value.calculatedEntry,
      'entryUnit': value.entryUnit,
      'maxVialSizeMl': value.maxVialSizeMl,
      'createdAt': _date(value.createdAt),
      'updatedAt': _date(value.updatedAt),
    };

SavedReconstitutionCalculation _deserializeSavedReconstitution(Map<String, Object?> json) => SavedReconstitutionCalculation(
      id: _str(json, 'id'),
      name: _str(json, 'name'),
      ownerMedicationId: _optStr(json, 'ownerMedicationId'),
      medicationName: _optStr(json, 'medicationName'),
      strengthValue: _dbl(json, 'strengthValue'),
      strengthUnit: _str(json, 'strengthUnit'),
      solventVolumeMl: _dbl(json, 'solventVolumeMl'),
      perMlConcentration: _dbl(json, 'perMlConcentration'),
      calculatedUnits: _dbl(json, 'calculatedUnits'),
      syringeSizeMl: _dbl(json, 'syringeSizeMl'),
      diluentName: _optStr(json, 'diluentName'),
      calculatedEntry: _optDbl(json, 'calculatedEntry'),
      entryUnit: _optStr(json, 'entryUnit'),
      maxVialSizeMl: _optDbl(json, 'maxVialSizeMl'),
      createdAt: _optDate(json, 'createdAt'),
      updatedAt: _optDate(json, 'updatedAt'),
    );

Map<String, Object?> _serializeSealedVialBatch(SealedVialBatch value) => {
      'name': value.name,
      'count': value.count,
    };

SealedVialBatch _deserializeSealedVialBatch(Map<String, Object?> json) => SealedVialBatch(
      name: _optStr(json, 'name'),
      count: _int(json, 'count'),
    );

String? _date(DateTime? value) => value?.toUtc().toIso8601String();

DateTime _dateReq(Map<String, Object?> json, String key) =>
    DateTime.parse(_str(json, key));

DateTime? _optDate(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  return DateTime.parse(value as String);
}

String _str(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Missing or invalid "$key" in backup record');
  }
  return value;
}

String? _optStr(Map<String, Object?> json, String key) {
  final value = json[key];
  return value as String?;
}

double _dbl(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value.toDouble();
  if (value is double) return value;
  throw FormatException('Missing or invalid "$key" in backup record');
}

double? _optDbl(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value.toDouble();
  return value as double?;
}

int _int(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Missing or invalid "$key" in backup record');
}

int? _optInt(Map<String, Object?> json, String key) {
  final value = json[key];
  return value as int?;
}

bool _bool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Missing or invalid "$key" in backup record');
  }
  return value;
}

List<int> _intList(Map<String, Object?> json, String key) {
  final values = _optList(json, key);
  if (values == null) {
    throw FormatException('Missing or invalid "$key" in backup record');
  }
  return values.map((value) => value as int).toList(growable: false);
}

List<int>? _optIntList(Map<String, Object?> json, String key) {
  final values = _optList(json, key);
  return values?.map((value) => value as int).toList(growable: false);
}

List<Object?>? _optList(Map<String, Object?> json, String key) {
  final value = json[key];
  return value as List<Object?>?;
}

VolumeUnit? _optVolumeUnit(Map<String, Object?> json, String key) {
  final value = _optStr(json, key);
  if (value == null || value.isEmpty) {
    return null;
  }
  return VolumeUnit.values.byName(value);
}