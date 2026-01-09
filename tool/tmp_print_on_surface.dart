import 'package:flutter/material.dart';

void main() {
  const primarySeed = Color(0xFF09A8BD);

  final schemeLight = ColorScheme.fromSeed(seedColor: primarySeed);
  final schemeDark = ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.dark,
  );

  String hex(Color c) =>
      '0x${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  // ignore: avoid_print
  print('seed=${hex(primarySeed)}');
  // ignore: avoid_print
  print('light.onSurface=${hex(schemeLight.onSurface)}');
  // ignore: avoid_print
  print('dark.onSurface=${hex(schemeDark.onSurface)}');
}
