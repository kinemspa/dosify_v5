import 'dart:io';

/// Verifies that generated Android brand assets exist.
///
/// Usage:
///   dart run tool/verify_android_brand_assets.dart
void main() {
  final requiredPaths = <String>[
    // Adaptive icon requirements.
    'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    'android/app/src/main/res/values/colors.xml',

    // Legacy launcher icons (densities).
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',

    // Adaptive foreground drawables (densities).
    'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png',
    'android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png',
    'android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png',
    'android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png',
    'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',

    // Native splash outputs (at least ensure the key bitmaps exist).
    'android/app/src/main/res/drawable/launch_background.xml',
    'android/app/src/main/res/drawable-v21/launch_background.xml',
    'android/app/src/main/res/drawable/background.png',
    'android/app/src/main/res/drawable-v21/background.png',
    'android/app/src/main/res/drawable-mdpi/splash.png',
    'android/app/src/main/res/drawable-hdpi/splash.png',
    'android/app/src/main/res/drawable-xhdpi/splash.png',
    'android/app/src/main/res/drawable-xxhdpi/splash.png',
    'android/app/src/main/res/drawable-xxxhdpi/splash.png',

    // Android 12 splash images.
    'android/app/src/main/res/drawable-mdpi/android12splash.png',
    'android/app/src/main/res/drawable-hdpi/android12splash.png',
    'android/app/src/main/res/drawable-xhdpi/android12splash.png',
    'android/app/src/main/res/drawable-xxhdpi/android12splash.png',
    'android/app/src/main/res/drawable-xxxhdpi/android12splash.png',

    // Notification large icon.
    'android/app/src/main/res/drawable/ic_notification_large.png',
  ];

  final missing = <String>[];
  for (final path in requiredPaths) {
    if (!File(path).existsSync()) {
      missing.add(path);
    }
  }

  if (missing.isNotEmpty) {
    stderr.writeln('Missing required Android brand assets:');
    for (final path in missing) {
      stderr.writeln(' - $path');
    }
    stderr.writeln('\nRegenerate with:');
    stderr.writeln(' - dart run flutter_launcher_icons');
    stderr.writeln(' - dart run flutter_native_splash:create');
    stderr.writeln(' - dart run tool/logo/generate_logo_variants.dart');
    exitCode = 1;
    return;
  }

  stdout.writeln('OK: Android brand assets present (${requiredPaths.length} files)');
}
