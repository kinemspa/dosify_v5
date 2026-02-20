import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dosifi_v5/src/core/backup/backup_constants.dart';
import 'package:dosifi_v5/src/core/backup/backup_models.dart';
import 'package:dosifi_v5/src/core/hive/hive_encryption_key_service.dart';

class BackupZipCodec {
  const BackupZipCodec();

  Future<({Uint8List zipBytes, BackupResult result})> createBackupZip() async {
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

    for (final boxName in kBackupHiveBoxNames) {
      // Open with cipher in case box was closed (normally already open from bootstrap).
      final box = await Hive.openBox<dynamic>(
        boxName,
        encryptionCipher: HiveEncryptionKeyService.cipher,
      );
      final boxPath = box.path;
      await box.close();

      if (boxPath == null) {
        continue;
      }

      final file = File(boxPath);
      final exists = await Isolate.run(() => file.existsSync());
      if (!exists) {
        // Treat missing files as "skipped" rather than failing the whole backup.
        continue;
      }

      final bytes = await Isolate.run(() => file.readAsBytesSync());
      final fileNameInZip = '$kBackupHiveFolderPath/$boxName.hive';

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

    return (
      zipBytes: zipBytes,
      result: BackupResult(
        createdAtUtc: createdAtUtc,
        hiveBoxesIncluded: hiveEntries.length,
        sharedPrefsKeysIncluded: prefs.getKeys().length,
      ),
    );
  }

  Future<RestoreResult> restoreFromBackupZip(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes, verify: true);

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

    if (manifest.backupSchemaVersion > BackupManifest.currentBackupSchemaVersion) {
      throw const BackupFormatException(
        'Backup format is newer than this app can restore',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final currentHiveSchemaVersion = prefs.getInt('hive_schema_version') ?? 1;
    if (manifest.hiveSchemaVersion > currentHiveSchemaVersion) {
      throw const BackupFormatException(
        'Backup was created with a newer Hive schema version',
      );
    }

    var restoredPrefsCount = 0;
    final sharedPrefsFile = archive.findFile(manifest.sharedPrefsFile);
    if (sharedPrefsFile != null) {
      final prefsJsonString = utf8.decode(sharedPrefsFile.content as List<int>);
      final prefsJson = jsonDecode(prefsJsonString);
      if (prefsJson is Map<String, Object?>) {
        restoredPrefsCount = await _restoreSharedPreferences(prefs, prefsJson);
      }
    }

    // Resolve current on-device paths for each box before overwriting.
    final boxPaths = <String, String>{};
    for (final boxName in kBackupHiveBoxNames) {
      final box = await Hive.openBox<dynamic>(
        boxName,
        encryptionCipher: HiveEncryptionKeyService.cipher,
      );
      final path = box.path;
      if (path != null) {
        boxPaths[boxName] = path;
      }
      await box.close();
    }

    var restoredCount = 0;
    final missing = <String>[];

    for (final boxName in kBackupHiveBoxNames) {
      final entry = manifest.hiveBoxes.where((e) => e.name == boxName).toList();
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
      await Isolate.run(() => File(targetPath).writeAsBytesSync(bytes, flush: true));
      restoredCount += 1;
    }

    // Reopen boxes so the app sees updated data.
    // Must use the encryption cipher — boxes on disk are now encrypted.
    for (final boxName in kBackupHiveBoxNames) {
      await Hive.openBox<dynamic>(
        boxName,
        encryptionCipher: HiveEncryptionKeyService.cipher,
      );
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
}
