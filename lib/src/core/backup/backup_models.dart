import 'dart:convert';

class BackupManifest {
  const BackupManifest({
    required this.backupSchemaVersion,
    required this.createdAtUtcIso,
    required this.appVersion,
    required this.buildNumber,
    required this.hiveSchemaVersion,
    required this.hiveBoxes,
    required this.sharedPrefsFile,
  });

  static const currentBackupSchemaVersion = 1;

  final int backupSchemaVersion;
  final String createdAtUtcIso;
  final String appVersion;
  final String buildNumber;
  final int hiveSchemaVersion;
  final List<BackupHiveBoxEntry> hiveBoxes;
  final String sharedPrefsFile;

  Map<String, Object?> toJson() => {
        'backupSchemaVersion': backupSchemaVersion,
        'createdAtUtcIso': createdAtUtcIso,
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'hiveSchemaVersion': hiveSchemaVersion,
        'hiveBoxes': hiveBoxes.map((e) => e.toJson()).toList(growable: false),
        'sharedPrefsFile': sharedPrefsFile,
      };

  factory BackupManifest.fromJson(Map<String, Object?> json) {
    final backupSchemaVersion = json['backupSchemaVersion'];
    final createdAtUtcIso = json['createdAtUtcIso'];
    final appVersion = json['appVersion'];
    final buildNumber = json['buildNumber'];
    final hiveSchemaVersion = json['hiveSchemaVersion'];
    final hiveBoxes = json['hiveBoxes'];
    final sharedPrefsFile = json['sharedPrefsFile'];

    if (backupSchemaVersion is! int ||
        createdAtUtcIso is! String ||
        appVersion is! String ||
        buildNumber is! String ||
        hiveSchemaVersion is! int ||
        hiveBoxes is! List ||
        sharedPrefsFile is! String) {
      throw const BackupFormatException('Invalid manifest structure');
    }

    return BackupManifest(
      backupSchemaVersion: backupSchemaVersion,
      createdAtUtcIso: createdAtUtcIso,
      appVersion: appVersion,
      buildNumber: buildNumber,
      hiveSchemaVersion: hiveSchemaVersion,
      hiveBoxes: hiveBoxes
          .map((e) => BackupHiveBoxEntry.fromJson(e as Map<String, Object?>))
          .toList(growable: false),
      sharedPrefsFile: sharedPrefsFile,
    );
  }

  String toPrettyJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());
}

class BackupHiveBoxEntry {
  const BackupHiveBoxEntry({
    required this.name,
    required this.file,
    required this.byteLength,
  });

  final String name;
  final String file;
  final int byteLength;

  Map<String, Object?> toJson() => {
        'name': name,
        'file': file,
        'byteLength': byteLength,
      };

  factory BackupHiveBoxEntry.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final file = json['file'];
    final byteLength = json['byteLength'];

    if (name is! String || file is! String || byteLength is! int) {
      throw const BackupFormatException('Invalid hive box entry');
    }

    return BackupHiveBoxEntry(name: name, file: file, byteLength: byteLength);
  }
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

class BackupResult {
  const BackupResult({
    required this.createdAtUtc,
    required this.hiveBoxesIncluded,
    required this.sharedPrefsKeysIncluded,
  });

  final DateTime createdAtUtc;
  final int hiveBoxesIncluded;
  final int sharedPrefsKeysIncluded;
}

class RestoreResult {
  const RestoreResult({
    required this.hiveBoxesRestored,
    required this.hiveBoxesMissing,
    required this.sharedPrefsKeysRestored,
  });

  final int hiveBoxesRestored;
  final List<String> hiveBoxesMissing;
  final int sharedPrefsKeysRestored;
}
