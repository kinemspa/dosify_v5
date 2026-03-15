import 'package:flutter/foundation.dart';

class GoogleDriveBackupConfig {
  static const String androidServerClientIdDefineName =
      'SKEDUX_GOOGLE_DRIVE_SERVER_CLIENT_ID';
  static const String webClientIdDefineName =
      'SKEDUX_GOOGLE_SIGN_IN_WEB_CLIENT_ID';
  static const String iosClientIdDefineName =
      'SKEDUX_GOOGLE_SIGN_IN_IOS_CLIENT_ID';

  static const String _androidServerClientId = String.fromEnvironment(
    androidServerClientIdDefineName,
  );
  static const String _webClientId = String.fromEnvironment(
    webClientIdDefineName,
  );
  static const String _iosClientId = String.fromEnvironment(
    iosClientIdDefineName,
  );

  static String? get clientIdForCurrentPlatform {
    if (kIsWeb) return _nullIfBlank(_webClientId);

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => _nullIfBlank(_iosClientId),
      _ => null,
    };
  }

  static String? get serverClientIdForCurrentPlatform {
    if (kIsWeb) return null;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _nullIfBlank(_androidServerClientId),
      _ => null,
    };
  }

  static String get missingConfigurationMessage {
    if (kIsWeb) {
      return 'Google Drive backup is not configured. Build with '
          '--dart-define=$webClientIdDefineName=YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com.';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        'Google Drive backup is not configured. Build with '
            '--dart-define=$androidServerClientIdDefineName=YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com.',
      TargetPlatform.iOS || TargetPlatform.macOS =>
        'Google Drive backup is not configured. Build with '
            '--dart-define=$iosClientIdDefineName=YOUR_IOS_OAUTH_CLIENT_ID.apps.googleusercontent.com.',
      _ =>
        'Google Drive backup is not configured for this platform.',
    };
  }

  static bool get hasExplicitConfiguration {
    return clientIdForCurrentPlatform != null ||
        serverClientIdForCurrentPlatform != null;
  }

  static String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}