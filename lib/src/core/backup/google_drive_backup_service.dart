import 'dart:async';

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'package:skedux/src/core/backup/google_drive_backup_config.dart';
import 'package:skedux/src/core/backup/backup_zip_codec.dart';
import 'package:skedux/src/core/backup/backup_models.dart';

class GoogleDriveBackupService {
  GoogleDriveBackupService({BackupZipCodec? codec, GoogleSignIn? googleSignIn})
    : _codec = codec ?? const BackupZipCodec(),
      _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: _scopes,
            clientId: GoogleDriveBackupConfig.clientIdForCurrentPlatform,
            serverClientId:
                GoogleDriveBackupConfig.serverClientIdForCurrentPlatform,
          );

  static const _scopes = <String>[drive.DriveApi.driveAppdataScope];

  static const _fileNamePrefix = 'skedux_backup_';

  final BackupZipCodec _codec;
  final GoogleSignIn _googleSignIn;

  static bool get isEnabledInThisBuild =>
      GoogleDriveBackupConfig.hasExplicitConfiguration;

  Future<List<DriveBackupEntry>> listBackups() async {
    final account = await _ensureSignedIn();
    final client = await _authClient(account);
    final api = drive.DriveApi(client);

    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains '$_fileNamePrefix'",
      orderBy: 'createdTime desc',
      pageSize: 20,
      $fields: 'files(id,name,createdTime,size)',
    );
    client.close();

    final files = result.files ?? const <drive.File>[];
    return files
        .where((file) => file.id != null && file.name != null)
        .map(
          (file) => DriveBackupEntry(
            id: file.id!,
            name: file.name!,
            createdAtUtc: file.createdTime?.toUtc(),
            sizeBytes: file.size == null ? null : int.tryParse(file.size!),
          ),
        )
        .toList(growable: false);
  }

  Future<BackupResult> backupToDrive({String? password}) async {
    final account = await _ensureSignedIn();
    final client = await _authClient(account);
    final api = drive.DriveApi(client);

    final created = await _codec.createBackupZip(password: password);
    final extension = created.isEncrypted ? 'skbackup' : 'zip';
    final fileName =
        '$_fileNamePrefix${created.result.createdAtUtc.toIso8601String().replaceAll(':', '-')}.${extension}';

    final file = drive.File(name: fileName, parents: const ['appDataFolder']);

    final media = drive.Media(
      Stream.value(created.zipBytes),
      created.zipBytes.length,
    );
    await api.files.create(file, uploadMedia: media, $fields: 'id');

    // Best-effort cleanup: keep appDataFolder tidy.
    unawaited(_deleteOldBackups(api));

    client.close();
    return created.result;
  }

  Future<RestoreResult> restoreLatestFromDrive({String? password}) async {
    final bytes = await downloadLatestBackupZip();
    return _codec.restoreFromBackupZip(bytes, password: password);
  }

  Future<Uint8List> downloadLatestBackupZip() async {
    final backups = await listBackups();
    if (backups.isEmpty) {
      throw const BackupFormatException('No backups found in Google Drive');
    }
    return downloadBackupZipById(backups.first.id);
  }

  Future<Uint8List> downloadBackupZipById(String fileId) async {
    final account = await _ensureSignedIn();
    final client = await _authClient(account);
    final api = drive.DriveApi(client);

    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (media is! drive.Media) {
      client.close();
      throw const BackupFormatException('Failed to download backup');
    }

    final bytes = await _readAllBytes(media.stream);
    client.close();
    return bytes;
  }

  Future<void> deleteBackupById(String fileId) async {
    final account = await _ensureSignedIn();
    final client = await _authClient(account);
    final api = drive.DriveApi(client);

    await api.files.delete(fileId);
    client.close();
  }

  Future<GoogleSignInAccount> _ensureSignedIn() async {
    if (!GoogleDriveBackupConfig.hasExplicitConfiguration) {
      throw BackupFormatException(
        GoogleDriveBackupConfig.missingConfigurationMessage,
      );
    }

    try {
      final existing = await _googleSignIn.signInSilently().timeout(
        const Duration(seconds: 12),
        onTimeout: () => null,
      );
      if (existing != null) return existing;

      final interactive = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 60),
        onTimeout: () => null,
      );
      if (interactive != null) return interactive;

      throw const BackupFormatException(
        'Google sign-in failed. Make sure a Google account is added to this device, then try again.',
      );
    } on TimeoutException {
      throw const BackupFormatException(
        'Google sign-in timed out. Check your connection and try again.',
      );
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  Future<http.Client> _authClient(GoogleSignInAccount account) async {
    try {
      final headers = await account.authHeaders;
      return _GoogleAuthClient(headers);
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  BackupFormatException _mapPlatformException(PlatformException error) {
    final message = error.message?.trim();
    final configurationIssue =
        message != null &&
        (message.contains('serverClientId') ||
            message.contains('clientId') ||
            message.contains('configuration'));

    if (configurationIssue) {
      return BackupFormatException(
        '${GoogleDriveBackupConfig.missingConfigurationMessage}${message.isEmpty ? '' : ' $message'}',
      );
    }

    return BackupFormatException(
      message == null || message.isEmpty
          ? 'Google sign-in failed. Check your account and try again.'
          : 'Google sign-in failed. $message',
    );
  }

  Future<void> _deleteOldBackups(drive.DriveApi api) async {
    try {
      final result = await api.files.list(
        spaces: 'appDataFolder',
        q: "name contains '$_fileNamePrefix'",
        orderBy: 'createdTime desc',
        pageSize: 20,
        $fields: 'files(id,name,createdTime)',
      );

      final files = result.files ?? const <drive.File>[];
      if (files.length <= 5) return;

      final toDelete = files.skip(5);
      for (final f in toDelete) {
        if (f.id == null) continue;
        await api.files.delete(f.id!);
      }
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<Uint8List> _readAllBytes(Stream<List<int>> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }
}

class DriveBackupEntry {
  const DriveBackupEntry({
    required this.id,
    required this.name,
    required this.createdAtUtc,
    required this.sizeBytes,
  });

  final String id;
  final String name;
  final DateTime? createdAtUtc;
  final int? sizeBytes;
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
