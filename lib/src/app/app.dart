import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

class DosifiApp extends ConsumerWidget {
  const DosifiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primarySeed = Color(0xFF09A8BD);
    const secondary = Color(0xFFEC873F);

    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primarySeed, brightness: Brightness.light),
      useMaterial3: true,
    ).copyWith(
      appBarTheme: const AppBarTheme(centerTitle: true),
    );

    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primarySeed, brightness: Brightness.dark),
      useMaterial3: true,
    );

    return MaterialApp.router(
      title: 'Dosifi v5',
      theme: light,
      darkTheme: dark,
      routerConfig: router,
    );
  }
}

