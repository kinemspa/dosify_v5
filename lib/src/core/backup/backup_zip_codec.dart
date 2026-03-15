import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skedux/src/core/backup/backup_constants.dart';
import 'package:skedux/src/core/backup/backup_models.dart';
import 'package:skedux/src/core/backup/backup_protection_service.dart';
import 'package:skedux/src/core/backup/backup_serialization.dart';
import 'package:skedux/src/core/hive/hive_encryption_key_service.dart';
import 'package:skedux/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:skedux/src/features/medications/domain/inventory_log.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/entry_status_change_log.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/supplies/domain/stock_movement.dart';
import 'package:skedux/src/features/supplies/domain/supply.dart';

class BackupZipCodec {
  const BackupZipCodec();

  static const BackupProtectionService _protectionService =
      BackupProtectionService();

  static const _restoreCompatibilityMessage =
      'This backup could not be opened by the current app install. '
      'If Skedux was reinstalled after the backup was created, the encryption key changed and that older backup can no longer be restored.';
  static const _portableRestoreFailureMessage =
      'This backup file could not be restored. It may be corrupted or from an unsupported app version.';

  Future<Box<dynamic>> _openBackupBox(String boxName) {
    return switch (boxName) {
      'medications' =>
        Hive.isBoxOpen(boxName)
            ? Future.value(Hive.box<Medication>(boxName))
            : Hive.openBox<Medication>(
                boxName,
                encryptionCipher: HiveEncryptionKeyService.cipher,
              ),
      'schedules' =>
        Hive.isBoxOpen(boxName)
            ? Future.value(Hive.box<Schedule>(boxName))
            : Hive.openBox<Schedule>(
                boxName,
                encryptionCipher: HiveEncryptionKeyService.cipher,
              ),
      'entry_logs' =>
        Hive.isBoxOpen(boxName)
            ? Future.value(Hive.box<EntryLog>(boxName))
            : Hive.openBox<EntryLog>(
                boxName,
                encryptionCipher: HiveEncryptionKeyService.cipher,
              ),
      'entry_status_change_logs' =>
        Hive.isBoxOpen(boxName)
            ? Future.value(Hive.box<EntryStatusChangeLog>(boxName))
            : Hive.openBox<EntryStatusChangeLog>(
                boxName,
                encryptionCipher: HiveEncryptionKeyService.cipher,
              ),
      'supplies' =>
        Hive.isBoxOpen(boxName)
            ? Future.value(Hive.box<Supply>(boxName))
            : Hive.openBox<Supply>(
                boxName,
                encryptionCipher: HiveEncryptionKeyService.cipher,
              ),
      'stock_movements' =>
        Hive.isBoxOpen(boxName)
            ? Future.value(Hive.box<StockMovement>(boxName))
            : Hive.openBox<StockMovement>(
                boxName,
                encryptionCipher: HiveEncryptionKeyService.cipher,
              ),
      'inventory_logs' =>
        Hive.isBoxOpen(boxName)
            ? Future.value(Hive.box<InventoryLog>(boxName))
            : Hive.openBox<InventoryLog>(
                boxName,
                encryptionCipher: HiveEncryptionKeyService.cipher,
              ),
      SavedReconstitutionRepository.boxName =>
        Hive.isBoxOpen(boxName)
            ? Future.value(Hive.box<SavedReconstitutionCalculation>(boxName))
            : Hive.openBox<SavedReconstitutionCalculation>(
                boxName,
                encryptionCipher: HiveEncryptionKeyService.cipher,
              ),
      _ => Hive.openBox(
        boxName,
        encryptionCipher: HiveEncryptionKeyService.cipher,
      ),
    };
  }

  Future<({Uint8List zipBytes, BackupResult result, bool isEncrypted})>
  createBackupZip({String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    final createdAtUtc = DateTime.now().toUtc();

    final hiveSchemaVersion = prefs.getInt('hive_schema_version') ?? 1;

    final archive = Archive();

    final sharedPrefsJson = _encodeSharedPreferences(prefs);
    archive.addFile(
      ArchiveFile(
        kBackupSharedPrefsPath,
        sharedPrefsJson.length,
        sharedPrefsJson,
      ),
    );

    final hiveEntries = <BackupHiveBoxEntry>[];
    final recordCountsByBox = <String, int>{};
    var totalRecordsIncluded = 0;

    for (final boxName in kBackupHiveBoxNames) {
      final box = await _openBackupBox(boxName);
      final records = serializeBoxRecords(boxName, box.toMap());
      final bytes = encodeBackupRecords(records);
      final fileNameInZip = '$kBackupHiveFolderPath/$boxName.json';
      totalRecordsIncluded += records.length;
      recordCountsByBox[boxName] = records.length;

      archive.addFile(ArchiveFile(fileNameInZip, bytes.length, bytes));
      hiveEntries.add(
        BackupHiveBoxEntry(
          name: boxName,
          file: fileNameInZip,
          byteLength: bytes.length,
        ),
      );
    }

    final manifest = BackupManifest(
      backupSchemaVersion: BackupManifest.currentBackupSchemaVersion,
      createdAtUtcIso: createdAtUtc.toIso8601String(),
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      hiveSchemaVersion: hiveSchemaVersion,
      hiveBoxes: hiveEntries,
      sharedPrefsFile: kBackupSharedPrefsPath,
    );

    final manifestBytes = utf8.encode(manifest.toPrettyJsonString());
    archive.addFile(
      ArchiveFile(kBackupManifestPath, manifestBytes.length, manifestBytes),
    );

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final normalizedPassword = password?.trim();
    final isEncrypted =
        normalizedPassword != null && normalizedPassword.isNotEmpty;
    final protectedBytes = isEncrypted
        ? await _protectionService.encrypt(
            clearBytes: zipBytes,
            password: normalizedPassword,
          )
        : zipBytes;

    return (
      zipBytes: protectedBytes,
      result: BackupResult(
        createdAtUtc: createdAtUtc,
        hiveBoxesIncluded: hiveEntries.length,
        sharedPrefsKeysIncluded: prefs.getKeys().length,
        totalRecordsIncluded: totalRecordsIncluded,
        recordCountsByBox: recordCountsByBox,
      ),
      isEncrypted: isEncrypted,
    );
  }

  Future<Uint8List> prepareRestoreZipBytes(
    Uint8List zipBytes, {
    String? password,
  }) {
    return _decodeBackupBytes(zipBytes, password: password);
  }

  Future<RestoreResult> restoreFromBackupZip(
    Uint8List zipBytes, {
    String? password,
  }) async {
    final decodedZipBytes = await _decodeBackupBytes(
      zipBytes,
      password: password,
    );
    final archive = ZipDecoder().decodeBytes(decodedZipBytes, verify: true);

    final manifestFile = archive.findFile(kBackupManifestPath);
    if (manifestFile == null) {
      throw const BackupFormatException('Missing manifest.json');
    }

    final manifestJsonString = utf8.decode(manifestFile.content as List<int>);
    final manifestJson = jsonDecode(manifestJsonString);
    if (manifestJson is! Map<String, Object?>) {
      throw const BackupFormatException('Invalid manifest JSON');
    }

    final manifest = BackupManifest.fromJson(manifestJson);

    if (manifest.backupSchemaVersion >
        BackupManifest.currentBackupSchemaVersion) {
      throw const BackupFormatException(
        'Backup format is newer than this app can restore',
      );
    }

    if (manifest.backupSchemaVersion <= 1) {
      return _restoreLegacyEncryptedBackup(archive, manifest);
    }

    return _restorePortableBackup(archive, manifest);
  }

  Future<BackupPreview> inspectBackupZip(
    Uint8List zipBytes, {
    String? password,
  }) async {
    final decodedZipBytes = await _decodeBackupBytes(
      zipBytes,
      password: password,
    );
    final archive = ZipDecoder().decodeBytes(decodedZipBytes, verify: true);

    final manifestFile = archive.findFile(kBackupManifestPath);
    if (manifestFile == null) {
      throw const BackupFormatException('Missing manifest.json');
    }

    final manifestJsonString = utf8.decode(manifestFile.content as List<int>);
    final manifestJson = jsonDecode(manifestJsonString);
    if (manifestJson is! Map<String, Object?>) {
      throw const BackupFormatException('Invalid manifest JSON');
    }

    final manifest = BackupManifest.fromJson(manifestJson);

    final sharedPrefsFile = archive.findFile(manifest.sharedPrefsFile);
    var sharedPrefsKeysIncluded = 0;
    if (sharedPrefsFile != null) {
      final prefsJsonString = utf8.decode(sharedPrefsFile.content as List<int>);
      final prefsJson = jsonDecode(prefsJsonString);
      if (prefsJson is Map<String, Object?>) {
        sharedPrefsKeysIncluded = prefsJson.length;
      }
    }

    final recordCountsByBox = <String, int>{};
    for (final boxName in kBackupHiveBoxNames) {
      final entry = manifest.hiveBoxes.where((e) => e.name == boxName).toList();
      if (entry.isEmpty) {
        recordCountsByBox[boxName] = 0;
        continue;
      }

      final boxFileInZip = archive.findFile(entry.single.file);
      if (boxFileInZip == null) {
        recordCountsByBox[boxName] = 0;
        continue;
      }

      final records = decodeBackupRecords(boxFileInZip.content as List<int>);
      recordCountsByBox[boxName] = records.length;
    }

    return BackupPreview(
      createdAtUtc: DateTime.parse(manifest.createdAtUtcIso),
      sharedPrefsKeysIncluded: sharedPrefsKeysIncluded,
      recordCountsByBox: recordCountsByBox,
    );
  }

  Future<BackupPreview> validateBackupZip(
    Uint8List zipBytes, {
    String? password,
  }) async {
    final decodedZipBytes = await _decodeBackupBytes(
      zipBytes,
      password: password,
    );
    final archive = ZipDecoder().decodeBytes(decodedZipBytes, verify: true);

    final manifestFile = archive.findFile(kBackupManifestPath);
    if (manifestFile == null) {
      throw const BackupFormatException('Missing manifest.json');
    }

    final manifestJsonString = utf8.decode(manifestFile.content as List<int>);
    final manifestJson = jsonDecode(manifestJsonString);
    if (manifestJson is! Map<String, Object?>) {
      throw const BackupFormatException('Invalid manifest JSON');
    }

    final manifest = BackupManifest.fromJson(manifestJson);
    final preview = await inspectBackupZip(decodedZipBytes);

    try {
      for (final boxName in kBackupHiveBoxNames) {
        final entry = manifest.hiveBoxes
            .where((e) => e.name == boxName)
            .toList();
        if (entry.isEmpty) continue;

        final boxFileInZip = archive.findFile(entry.single.file);
        if (boxFileInZip == null) continue;

        final records = decodeBackupRecords(boxFileInZip.content as List<int>);
        for (final record in records) {
          deserializeBoxRecord(boxName, record);
        }
      }
    } catch (error) {
      throw _mapPortableRestoreFailure(error);
    }

    return preview;
  }

  Future<Uint8List> _decodeBackupBytes(Uint8List bytes, {String? password}) {
    return _protectionService.decrypt(bytes: bytes, password: password);
  }

  Future<RestoreResult> _restorePortableBackup(
    Archive archive,
    BackupManifest manifest,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHiveSchemaVersion = prefs.getInt('hive_schema_version') ?? 1;
    if (manifest.hiveSchemaVersion > currentHiveSchemaVersion) {
      throw const BackupFormatException(
        'Backup was created with a newer Hive schema version',
      );
    }

    final previousPrefsSnapshot = _snapshotSharedPreferences(prefs);

    var restoredPrefsCount = 0;
    final sharedPrefsFile = archive.findFile(manifest.sharedPrefsFile);
    if (sharedPrefsFile != null) {
      final prefsJsonString = utf8.decode(sharedPrefsFile.content as List<int>);
      final prefsJson = jsonDecode(prefsJsonString);
      if (prefsJson is Map<String, Object?>) {
        restoredPrefsCount = await _restoreSharedPreferencesReplacingExisting(
          prefs,
          prefsJson,
        );
      }
    }

    final boxes = <String, Box<dynamic>>{};
    final previousValues = <String, Map<dynamic, dynamic>>{};
    for (final boxName in kBackupHiveBoxNames) {
      final box = await _openBackupBox(boxName);
      boxes[boxName] = box;
      previousValues[boxName] = Map<dynamic, dynamic>.from(box.toMap());
    }

    var restoredCount = 0;
    final missing = <String>[];

    try {
      for (final boxName in kBackupHiveBoxNames) {
        final box = boxes[boxName]!;
        final entry = manifest.hiveBoxes
            .where((e) => e.name == boxName)
            .toList();
        if (entry.isEmpty) {
          missing.add(boxName);
          await box.clear();
          continue;
        }

        final boxFileInZip = archive.findFile(entry.single.file);
        if (boxFileInZip == null) {
          missing.add(boxName);
          await box.clear();
          continue;
        }

        final records = decodeBackupRecords(boxFileInZip.content as List<int>);
        final restoredMap = <dynamic, dynamic>{
          for (final record in records)
            deserializeBoxRecord(boxName, record).key: deserializeBoxRecord(
              boxName,
              record,
            ).value,
        };

        await box.clear();
        if (restoredMap.isNotEmpty) {
          await _putBoxEntries(box, restoredMap);
        }
        restoredCount += 1;
      }
    } catch (error) {
      await _restoreSharedPreferencesSnapshot(prefs, previousPrefsSnapshot);
      for (final entry in boxes.entries) {
        await entry.value.clear();
        final previous = previousValues[entry.key]!;
        if (previous.isNotEmpty) {
          await _putBoxEntries(entry.value, previous);
        }
      }
      throw _mapPortableRestoreFailure(error);
    }

    return RestoreResult(
      hiveBoxesRestored: restoredCount,
      hiveBoxesMissing: missing,
      sharedPrefsKeysRestored: restoredPrefsCount,
    );
  }

  Future<RestoreResult> _restoreLegacyEncryptedBackup(
    Archive archive,
    BackupManifest manifest,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHiveSchemaVersion = prefs.getInt('hive_schema_version') ?? 1;
    if (manifest.hiveSchemaVersion > currentHiveSchemaVersion) {
      throw const BackupFormatException(
        'Backup was created with a newer Hive schema version',
      );
    }

    final previousPrefsSnapshot = _snapshotSharedPreferences(prefs);

    var restoredPrefsCount = 0;
    final sharedPrefsFile = archive.findFile(manifest.sharedPrefsFile);
    if (sharedPrefsFile != null) {
      final prefsJsonString = utf8.decode(sharedPrefsFile.content as List<int>);
      final prefsJson = jsonDecode(prefsJsonString);
      if (prefsJson is Map<String, Object?>) {
        restoredPrefsCount = await _restoreSharedPreferencesReplacingExisting(
          prefs,
          prefsJson,
        );
      }
    }

    // Resolve current on-device paths from the already-open boxes.
    final boxPaths = <String, String>{};
    for (final boxName in kBackupHiveBoxNames) {
      final box = await _openBackupBox(boxName);
      final path = box.path;
      if (path != null) {
        boxPaths[boxName] = path;
      }
    }

    final previousBoxFiles = await _snapshotBoxFiles(boxPaths);

    // Close boxes before writing restored bytes so Hive releases file handles.
    await _closeBackupBoxes();

    var restoredCount = 0;
    final missing = <String>[];

    try {
      for (final boxName in kBackupHiveBoxNames) {
        final entry = manifest.hiveBoxes
            .where((e) => e.name == boxName)
            .toList();
        if (entry.isEmpty) {
          missing.add(boxName);
          continue;
        }

        final zipPath = entry.single.file;
        final boxFileInZip = archive.findFile(zipPath);
        if (boxFileInZip == null) {
          missing.add(boxName);
          continue;
        }

        final targetPath = boxPaths[boxName];
        if (targetPath == null) {
          missing.add(boxName);
          continue;
        }

        final bytes = Uint8List.fromList(boxFileInZip.content as List<int>);
        await Isolate.run(
          () => File(targetPath).writeAsBytesSync(bytes, flush: true),
        );
        restoredCount += 1;
      }

      for (final boxName in kBackupHiveBoxNames) {
        await _openBackupBox(boxName);
      }
    } catch (error) {
      await _closeBackupBoxes();
      await _restoreSharedPreferencesSnapshot(prefs, previousPrefsSnapshot);
      await _restoreBoxFiles(previousBoxFiles, boxPaths);

      for (final boxName in kBackupHiveBoxNames) {
        await _openBackupBox(boxName);
      }

      throw _mapLegacyRestoreFailure(error);
    }

    return RestoreResult(
      hiveBoxesRestored: restoredCount,
      hiveBoxesMissing: missing,
      sharedPrefsKeysRestored: restoredPrefsCount,
    );
  }

  List<int> _encodeSharedPreferences(SharedPreferences prefs) {
    final map = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      map[key] = prefs.get(key);
    }
    final jsonString = const JsonEncoder.withIndent('  ').convert(map);
    return utf8.encode(jsonString);
  }

  Map<String, Object?> _snapshotSharedPreferences(SharedPreferences prefs) {
    final map = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      map[key] = prefs.get(key);
    }
    return map;
  }

  Future<int> _restoreSharedPreferences(
    SharedPreferences prefs,
    Map<String, Object?> json,
  ) async {
    var restored = 0;
    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is String) {
        await prefs.setString(key, value);
        restored += 1;
      } else if (value is int) {
        await prefs.setInt(key, value);
        restored += 1;
      } else if (value is double) {
        await prefs.setDouble(key, value);
        restored += 1;
      } else if (value is bool) {
        await prefs.setBool(key, value);
        restored += 1;
      } else if (value is List) {
        final strings = value.whereType<String>().toList(growable: false);
        if (strings.length == value.length) {
          await prefs.setStringList(key, strings);
          restored += 1;
        }
      }
    }

    return restored;
  }

  Future<int> _restoreSharedPreferencesReplacingExisting(
    SharedPreferences prefs,
    Map<String, Object?> snapshot,
  ) async {
    final currentKeys = prefs.getKeys().toList(growable: false);
    for (final key in currentKeys) {
      if (!snapshot.containsKey(key)) {
        await prefs.remove(key);
      }
    }
    return _restoreSharedPreferences(prefs, snapshot);
  }

  Future<void> _restoreSharedPreferencesSnapshot(
    SharedPreferences prefs,
    Map<String, Object?> snapshot,
  ) async {
    await _restoreSharedPreferencesReplacingExisting(prefs, snapshot);
  }

  Future<void> _putBoxEntries(
    Box<dynamic> box,
    Map<dynamic, dynamic> values,
  ) async {
    for (final entry in values.entries) {
      await box.put(entry.key, entry.value);
    }
  }

  Future<Map<String, Uint8List?>> _snapshotBoxFiles(
    Map<String, String> boxPaths,
  ) async {
    final snapshots = <String, Uint8List?>{};
    for (final entry in boxPaths.entries) {
      final file = File(entry.value);
      final exists = await Isolate.run(() => file.existsSync());
      snapshots[entry.key] = exists
          ? await Isolate.run(() => Uint8List.fromList(file.readAsBytesSync()))
          : null;
    }
    return snapshots;
  }

  Future<void> _restoreBoxFiles(
    Map<String, Uint8List?> snapshots,
    Map<String, String> boxPaths,
  ) async {
    for (final entry in boxPaths.entries) {
      final file = File(entry.value);
      final snapshot = snapshots[entry.key];
      if (snapshot == null) {
        final exists = await Isolate.run(() => file.existsSync());
        if (exists) {
          await Isolate.run(() => file.deleteSync());
        }
        continue;
      }
      await Isolate.run(() => file.writeAsBytesSync(snapshot, flush: true));
    }
  }

  Future<void> _closeBackupBoxes() async {
    for (final boxName in kBackupHiveBoxNames) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<dynamic>(boxName).close();
      }
    }
  }

  BackupFormatException _mapLegacyRestoreFailure(Object error) {
    if (error is BackupFormatException) {
      return error;
    }

    final message = error.toString().toLowerCase();
    if (message.contains('cipher') ||
        message.contains('decrypt') ||
        message.contains('checksum') ||
        message.contains('frame') ||
        message.contains('corrupt')) {
      return const BackupFormatException(_restoreCompatibilityMessage);
    }

    return BackupFormatException('Restore failed. $error');
  }

  BackupFormatException _mapPortableRestoreFailure(Object error) {
    if (error is BackupFormatException) {
      return error;
    }
    if (error is FormatException) {
      return const BackupFormatException(_portableRestoreFailureMessage);
    }
    return BackupFormatException('Restore failed. $error');
  }
}
