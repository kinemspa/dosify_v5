import 'dart:io';

import 'package:image/image.dart' as img;

const String _primaryLogoPath = 'assets/logo/logo_001_primary.png';
const String _whiteLogoPath = 'assets/logo/logo_001_white.png';
const String _androidIconPath = 'assets/logo/logo_001_android_icon.png';
const String _androidAdaptiveForegroundPath =
  'assets/logo/logo_001_white_adaptive_fg.png';
const String _splashLogoPath = 'assets/logo/logo_001_white_splash.png';
const String _androidNotificationLargeIconPath =
  'android/app/src/main/res/drawable/ic_notification_large.png';

// App brand seed (matches lib/src/app/app.dart)
const int _brandFillArgb = 0xFF09A8BD;

// Insets are expressed as a fraction of the canvas size per side.
// Larger inset => smaller visible logo.
const double _legacyIconInsetFraction = 0.22;
const double _adaptiveForegroundInsetFraction = 0.26;
const double _splashInsetFraction = 0.32;

Future<void> main() async {
  final primaryBytes = File(_primaryLogoPath).readAsBytesSync();
  final primary = img.decodePng(primaryBytes);
  if (primary == null) {
    stderr.writeln('Failed to decode $_primaryLogoPath');
    exitCode = 1;
    return;
  }

  final whiteLogo = _makeWhite(primary);
  File(_whiteLogoPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(whiteLogo));

  final adaptiveFg = _composeTransparentPadded(
    source: whiteLogo,
    size: 1024,
    insetFraction: _adaptiveForegroundInsetFraction,
  );
  File(_androidAdaptiveForegroundPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(adaptiveFg));

  final splashLogo = _composeTransparentPadded(
    source: whiteLogo,
    size: 1024,
    insetFraction: _splashInsetFraction,
  );
  File(_splashLogoPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(splashLogo));

  final androidIcon = _composeAndroidIcon(
    whiteLogo: whiteLogo,
    size: 1024,
    fillArgb: _brandFillArgb,
    insetFraction: _legacyIconInsetFraction,
  );
  File(_androidIconPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(androidIcon));

  stdout.writeln('Wrote: $_whiteLogoPath');
  stdout.writeln('Wrote: $_androidAdaptiveForegroundPath');
  stdout.writeln('Wrote: $_splashLogoPath');
  stdout.writeln('Wrote: $_androidIconPath');

  final notificationIcon = img.copyResize(
    primary,
    width: 256,
    height: 256,
    interpolation: img.Interpolation.cubic,
  );
  File(_androidNotificationLargeIconPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(notificationIcon));
  stdout.writeln('Wrote: $_androidNotificationLargeIconPath');
}

img.Image _composeTransparentPadded({
  required img.Image source,
  required int size,
  required double insetFraction,
}) {
  // Explicitly 4-channel RGBA so the transparent fill is preserved.
  final canvas = img.Image(
    width: size,
    height: size,
    numChannels: 4,
  );

  // Transparent background.
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final targetMax = (size * (1.0 - 2 * insetFraction)).round();
  final scale = _scaleToFit(
    srcWidth: source.width,
    srcHeight: source.height,
    maxWidth: targetMax,
    maxHeight: targetMax,
  );
  final scaledW = (source.width * scale).round();
  final scaledH = (source.height * scale).round();

  final resized = img.copyResize(
    source,
    width: scaledW,
    height: scaledH,
    interpolation: img.Interpolation.cubic,
  );

  final dstX = ((size - resized.width) / 2).round();
  final dstY = ((size - resized.height) / 2).round();
  img.compositeImage(canvas, resized, dstX: dstX, dstY: dstY);
  return canvas;
}

img.Image _makeWhite(img.Image source) {
  final out = img.Image.from(source);
  for (var y = 0; y < out.height; y++) {
    for (var x = 0; x < out.width; x++) {
      final pixel = out.getPixel(x, y);
      final a = pixel.a;
      if (a == 0) continue;
      out.setPixelRgba(x, y, 255, 255, 255, a);
    }
  }
  return out;
}

img.Image _composeAndroidIcon({
  required img.Image whiteLogo,
  required int size,
  required int fillArgb,
  required double insetFraction,
}) {
  final icon = img.Image(width: size, height: size);

  // Fill background.
  final r = (fillArgb >> 16) & 0xFF;
  final g = (fillArgb >> 8) & 0xFF;
  final b = fillArgb & 0xFF;
  img.fill(icon, color: img.ColorRgb8(r, g, b));

  // Scale logo to fit inside (1 - 2*inset) of the square.
  final targetMax = (size * (1.0 - 2 * insetFraction)).round();
  final scale = _scaleToFit(
    srcWidth: whiteLogo.width,
    srcHeight: whiteLogo.height,
    maxWidth: targetMax,
    maxHeight: targetMax,
  );
  final scaledW = (whiteLogo.width * scale).round();
  final scaledH = (whiteLogo.height * scale).round();

  final resized = img.copyResize(
    whiteLogo,
    width: scaledW,
    height: scaledH,
    interpolation: img.Interpolation.cubic,
  );

  final dstX = ((size - resized.width) / 2).round();
  final dstY = ((size - resized.height) / 2).round();
  img.compositeImage(icon, resized, dstX: dstX, dstY: dstY);

  return icon;
}

double _scaleToFit({
  required int srcWidth,
  required int srcHeight,
  required int maxWidth,
  required int maxHeight,
}) {
  if (srcWidth <= 0 || srcHeight <= 0) return 1.0;
  final scaleW = maxWidth / srcWidth;
  final scaleH = maxHeight / srcHeight;
  return scaleW < scaleH ? scaleW : scaleH;
}
