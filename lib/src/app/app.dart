import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_v5/src/app/router.dart';
import 'package:dosifi_v5/src/app/theme_mode_controller.dart';

class DosifiApp extends ConsumerWidget {
  const DosifiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primarySeed = Color(0xFF09A8BD);
    // const secondary = Color(0xFFEC873F);

    final schemeLight = ColorScheme.fromSeed(seedColor: primarySeed, brightness: Brightness.light).copyWith(
      // Pin the primary color exactly to the brand seed to avoid tonal shifts
      primary: primarySeed,
    );
    final baseLight = ThemeData(
      colorScheme: schemeLight,
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final light = baseLight.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        toolbarHeight: 48,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F3D5B),
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
iconTheme: WidgetStateProperty.resolveWith((states) =>
            IconThemeData(color: states.contains(WidgetState.selected) ? schemeLight.primary : Colors.white70, size: 22)),
labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            TextStyle(color: states.contains(WidgetState.selected) ? schemeLight.primary : Colors.white70, fontSize: 10)),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        horizontalTitleGap: 8,
        minLeadingWidth: 24,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseLight.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseLight.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: baseLight.colorScheme.surfaceContainerLowest,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: baseLight.colorScheme.primary,
selectionColor: baseLight.colorScheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: baseLight.colorScheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseLight.colorScheme.primary,
          foregroundColor: baseLight.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: baseLight.colorScheme.primary,
          foregroundColor: baseLight.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: baseLight.colorScheme.primary,
          side: BorderSide(color: baseLight.colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseLight.colorScheme.primary,
        foregroundColor: baseLight.colorScheme.onPrimary,
      ),
    );

    final schemeDark = ColorScheme.fromSeed(seedColor: primarySeed, brightness: Brightness.dark).copyWith(
      primary: primarySeed,
    );
    final baseDark = ThemeData(
      colorScheme: schemeDark,
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final dark = baseDark.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        toolbarHeight: 48,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F3D5B),
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
iconTheme: WidgetStateProperty.resolveWith((states) =>
            IconThemeData(color: states.contains(WidgetState.selected) ? schemeDark.primary : Colors.white70, size: 22)),
labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            TextStyle(color: states.contains(WidgetState.selected) ? schemeDark.primary : Colors.white70, fontSize: 10)),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        horizontalTitleGap: 8,
        minLeadingWidth: 24,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseDark.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseDark.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: baseDark.colorScheme.surfaceContainerHigh,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: baseDark.colorScheme.primary,
selectionColor: baseDark.colorScheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: baseDark.colorScheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseDark.colorScheme.primary,
          foregroundColor: baseDark.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: baseDark.colorScheme.primary,
          foregroundColor: baseDark.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: baseDark.colorScheme.primary,
          side: BorderSide(color: baseDark.colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseDark.colorScheme.primary,
        foregroundColor: baseDark.colorScheme.onPrimary,
      ),
    );

    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Dosifi v5',
      theme: light,
      darkTheme: dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

