import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Manages the AES-256 encryption key used for all Hive boxes.
///
/// The key is stored in Android Keystore (via flutter_secure_storage with
/// EncryptedSharedPreferences) and generated once on first launch.
///
/// NOTE — Backup portability:
/// Because the key is device-bound, backup zip files (which contain raw
/// encrypted Hive binary files) can only be restored on the same device.
/// Cross-device restore would require exporting data as JSON. This is tracked
/// as a future enhancement.
class HiveEncryptionKeyService {
  static const _keyName = 'dosifi_hive_aes_key_v1';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static HiveAesCipher? _cipher;

  /// The active cipher. Only valid after [initialize] has been called.
  static HiveAesCipher get cipher {
    assert(_cipher != null, 'HiveEncryptionKeyService.initialize() not called');
    return _cipher!;
  }

  /// Retrieves or generates the AES key and returns the ready-to-use cipher.
  /// Safe to call multiple times — returns cached cipher after first call.
  static Future<HiveAesCipher> initialize() async {
    if (_cipher != null) return _cipher!;
    final key = await _getOrCreateKey();
    _cipher = HiveAesCipher(key);
    return _cipher!;
  }

  static Future<Uint8List> _getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      return Uint8List.fromList(base64Decode(existing));
    }
    // Generate a fresh 32-byte (256-bit) key.
    final key = Uint8List.fromList(Hive.generateSecureKey());
    await _storage.write(key: _keyName, value: base64Encode(key));
    return key;
  }
}
