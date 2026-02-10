import 'dart:async';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'package:dosifi_v5/src/core/backup/backup_zip_codec.dart';
import 'package:dosifi_v5/src/core/backup/backup_models.dart';

class GoogleDriveBackupService {
  GoogleDriveBackupService({
    BackupZipCodec? codec,
    GoogleSignIn? googleSignIn,
  })  : _codec = codec ?? const BackupZipCodec(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const [drive.DriveApi.driveAppdataScope],
            );

  static const _fileNamePrefix = 'dosifi_backup_';

  final BackupZipCodec _codec;
  final GoogleSignIn _googleSignIn;

  Future<BackupResult> backupToDrive() async {
    final account = await _ensureSignedIn();
    final client = await _authClient(account);
    final api = drive.DriveApi(client);

    final created = await _codec.createBackupZip();
    final fileName =
        '$_fileNamePrefix${created.result.createdAtUtc.toIso8601String().replaceAll(':', '-')}.zip';

    final file = drive.File(
      name: fileName,
      parents: const ['appDataFolder'],
    );

    final media = drive.Media(Stream.value(created.zipBytes), created.zipBytes.length);
    await api.files.create(file, uploadMedia: media, $fields: 'id');

    // Best-effort cleanup: keep appDataFolder tidy.
    unawaited(_deleteOldBackups(api));

    client.close();
    return created.result;
  }

  Future<RestoreResult> restoreLatestFromDrive() async {
    final account = await _ensureSignedIn();
    final client = await _authClient(account);
    final api = drive.DriveApi(client);

    final latest = await _findLatestBackupFile(api);
    if (latest == null || latest.id == null) {
      client.close();
      throw const BackupFormatException('No backups found in Google Drive');
    }

    final media = await api.files.get(
      latest.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (media is! drive.Media) {
      client.close();
      throw const BackupFormatException('Failed to download backup');
    }

    final bytes = await _readAllBytes(media.stream);
    client.close();

    return _codec.restoreFromBackupZip(bytes);
  }

  Future<GoogleSignInAccount> _ensureSignedIn() async {
    final existing = await _googleSignIn.signInSilently();
    if (existing != null) return existing;

    final interactive = await _googleSignIn.signIn();
    if (interactive == null) {
      throw const BackupFormatException('Sign-in cancelled');
    }

    return interactive;
  }

  Future<http.Client> _authClient(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;
    return _GoogleAuthClient(headers);
  }

  Future<drive.File?> _findLatestBackupFile(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains '$_fileNamePrefix'",
      orderBy: 'createdTime desc',
      pageSize: 1,
      $fields: 'files(id,name,createdTime)',
    );

    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
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
