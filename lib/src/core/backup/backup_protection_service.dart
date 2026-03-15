import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'package:skedux/src/core/backup/backup_models.dart';

class BackupProtectionService {
  const BackupProtectionService();

  static const String _magic = 'SKEDUX_ENCRYPTED_BACKUP_V1';
  static const int _pbkdf2Iterations = 210000;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;

  static final AesGcm _algorithm = AesGcm.with256bits();
  static final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: 256,
  );

  bool isEncrypted(Uint8List bytes) => _tryParseEnvelope(bytes) != null;

  Future<Uint8List> encrypt({
    required Uint8List clearBytes,
    required String password,
  }) async {
    final normalizedPassword = password.trim();
    if (normalizedPassword.isEmpty) {
      throw const BackupFormatException('Backup password cannot be empty.');
    }

    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final secretKey = await _deriveKey(normalizedPassword, salt);
    final secretBox = await _algorithm.encrypt(
      clearBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final envelope = <String, Object?>{
      'magic': _magic,
      'algorithm': 'aes-256-gcm',
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': _pbkdf2Iterations,
      'saltBase64': base64Encode(salt),
      'nonceBase64': base64Encode(secretBox.nonce),
      'cipherTextBase64': base64Encode(secretBox.cipherText),
      'macBase64': base64Encode(secretBox.mac.bytes),
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<Uint8List> decrypt({
    required Uint8List bytes,
    String? password,
  }) async {
    final envelope = _tryParseEnvelope(bytes);
    if (envelope == null) {
      return bytes;
    }

    final normalizedPassword = password?.trim() ?? '';
    if (normalizedPassword.isEmpty) {
      throw const BackupPasswordRequiredException();
    }

    try {
      final salt = _decodeBase64(envelope, 'saltBase64');
      final nonce = _decodeBase64(envelope, 'nonceBase64');
      final cipherText = _decodeBase64(envelope, 'cipherTextBase64');
      final macBytes = _decodeBase64(envelope, 'macBase64');
      final secretKey = await _deriveKey(normalizedPassword, salt);
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
      final clearBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(clearBytes);
    } on SecretBoxAuthenticationError {
      throw const BackupInvalidPasswordException();
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      throw const BackupFormatException('Encrypted backup file is corrupted.');
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) {
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  Map<String, Object?>? _tryParseEnvelope(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        return null;
      }

      final map = Map<String, Object?>.from(decoded);
      if (map['magic'] != _magic) {
        return null;
      }
      return map;
    } catch (_) {
      return null;
    }
  }

  List<int> _decodeBase64(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw const BackupFormatException(
        'Encrypted backup metadata is invalid.',
      );
    }
    try {
      return base64Decode(value);
    } catch (_) {
      throw const BackupFormatException(
        'Encrypted backup metadata is invalid.',
      );
    }
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
