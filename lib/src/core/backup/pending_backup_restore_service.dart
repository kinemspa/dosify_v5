import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skedux/src/core/backup/backup_models.dart';
import 'package:skedux/src/core/backup/backup_zip_codec.dart';

class PendingBackupRestoreService {
  const PendingBackupRestoreService._();

  static const _pendingRestorePathKey = 'backup.pending_restore_path_v1';
  static const _lastRestoreNoticeKey = 'backup.last_restore_notice_v1';
  static const _lastRestoreNoticeIsErrorKey =
      'backup.last_restore_notice_is_error_v1';

  static Future<void> stageRestore(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/pending_restore.zip');
    await file.writeAsBytes(bytes, flush: true);
    await prefs.setString(_pendingRestorePathKey, file.path);
    await prefs.remove(_lastRestoreNoticeKey);
    await prefs.remove(_lastRestoreNoticeIsErrorKey);
  }

  static Future<RestoreResult?> applyPendingRestoreIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_pendingRestorePathKey);
    if (path == null || path.isEmpty) {
      return null;
    }

    final file = File(path);
    try {
      final exists = await Isolate.run(() => file.existsSync());
      if (!exists) {
        return null;
      }

      final bytes = await Isolate.run(() => file.readAsBytesSync());
      final result = await const BackupZipCodec().restoreFromBackupZip(bytes);
      await prefs.setString(
        _lastRestoreNoticeKey,
        'Backup restored: ${result.hiveBoxesRestored} boxes and ${result.sharedPrefsKeysRestored} settings applied.',
      );
      await prefs.setBool(_lastRestoreNoticeIsErrorKey, false);
      return result;
    } catch (error) {
      await prefs.setString(
        _lastRestoreNoticeKey,
        error is BackupFormatException
            ? error.message
            : 'Backup restore failed: $error',
      );
      await prefs.setBool(_lastRestoreNoticeIsErrorKey, true);
      rethrow;
    } finally {
      await prefs.remove(_pendingRestorePathKey);
      final exists = await Isolate.run(() => file.existsSync());
      if (exists) {
        await Isolate.run(() => file.deleteSync());
      }
    }
  }

  static Future<({String message, bool isError})?>
  consumeLastRestoreNotice() async {
    final prefs = await SharedPreferences.getInstance();
    final message = prefs.getString(_lastRestoreNoticeKey);
    if (message == null || message.isEmpty) {
      return null;
    }

    final isError = prefs.getBool(_lastRestoreNoticeIsErrorKey) ?? false;
    await prefs.remove(_lastRestoreNoticeKey);
    await prefs.remove(_lastRestoreNoticeIsErrorKey);
    return (message: message, isError: isError);
  }
}
