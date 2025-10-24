// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:dosifi_v5/src/app/router.dart';
import 'package:dosifi_v5/src/app/theme_mode_controller.dart';

class DosifiApp extends ConsumerWidget {
  const DosifiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primarySeed = Color(0xFF09A8BD);
    // const secondary = Color(0xFFEC873F);

    final schemeLight = ColorScheme.fromSeed(seedColor: primarySeed)
        .copyWith(
          // Pin the primary color exactly to the brand seed to avoid tonal shifts
          primary: primarySeed,
        );
    final baseLight = ThemeData(
      colorScheme: schemeLight,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    final lightTextTheme = baseLight.textTheme.copyWith(
      bodyMedium: baseLight.textTheme.bodyMedium?.copyWith(fontSize: 13),
      bodySmall: baseLight.textTheme.bodySmall?.copyWith(fontSize: 11),
      titleSmall: baseLight.textTheme.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: baseLight.textTheme.labelLarge?.copyWith(fontSize: 12),
    );
    final light = baseLight.copyWith(
      textTheme: lightTextTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        toolbarHeight: 48,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F3D5B),
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? schemeLight.primary : Colors.white70,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? schemeLight.primary : Colors.white70,
            fontSize: 10,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        horizontalTitleGap: 8,
        minLeadingWidth: 24,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        isCollapsed: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: const BoxConstraints(minHeight: 36),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseLight.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseLight.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseLight.colorScheme.outlineVariant),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseLight.colorScheme.primary, width: 2),
        ),
        errorStyle: const TextStyle(fontSize: 0, height: 0),
        filled: true,
        fillColor: baseLight.colorScheme.surfaceContainerLowest,
        hintStyle: lightTextTheme.bodyMedium?.copyWith(
          color: baseLight.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
        helperStyle: lightTextTheme.bodySmall?.copyWith(
          color: baseLight.colorScheme.onSurfaceVariant.withValues(alpha: 0.60),
        ),
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
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return baseLight.colorScheme.primary;
          return Colors.transparent; // no fill when unchecked
        }),
        checkColor: WidgetStatePropertyAll(baseLight.colorScheme.onPrimary),
        side: WidgetStateBorderSide.resolveWith((states) {
          // Match design system border width (0.75px) for consistency with text fields
          final color = baseLight.colorScheme.outlineVariant.withValues(alpha: 0.50);
          return BorderSide(color: color, width: 0.75);
        }),
        overlayColor: WidgetStatePropertyAll(baseLight.colorScheme.primary.withValues(alpha: 0.08)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseLight.colorScheme.primary,
        foregroundColor: baseLight.colorScheme.onPrimary,
      ),
    );

    final schemeDark = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
    ).copyWith(primary: primarySeed);
    final baseDark = ThemeData(
      colorScheme: schemeDark,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    final darkTextTheme = baseDark.textTheme.copyWith(
      bodyMedium: baseDark.textTheme.bodyMedium?.copyWith(fontSize: 13),
      bodySmall: baseDark.textTheme.bodySmall?.copyWith(fontSize: 11),
      titleSmall: baseDark.textTheme.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: baseDark.textTheme.labelLarge?.copyWith(fontSize: 12),
    );
    final dark = baseDark.copyWith(
      textTheme: darkTextTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        toolbarHeight: 48,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F3D5B),
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? schemeDark.primary : Colors.white70,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? schemeDark.primary : Colors.white70,
            fontSize: 10,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        horizontalTitleGap: 8,
        minLeadingWidth: 24,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        isCollapsed: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: const BoxConstraints(minHeight: 36),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseDark.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseDark.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseDark.colorScheme.outlineVariant),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseDark.colorScheme.primary, width: 2),
        ),
        errorStyle: const TextStyle(fontSize: 0, height: 0),
        filled: true,
        fillColor: baseDark.colorScheme.surfaceContainerHigh,
        hintStyle: darkTextTheme.bodyMedium?.copyWith(
          color: baseDark.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
        helperStyle: darkTextTheme.bodySmall?.copyWith(
          color: baseDark.colorScheme.onSurfaceVariant.withValues(alpha: 0.60),
        ),
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
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return baseDark.colorScheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(baseDark.colorScheme.onPrimary),
        side: WidgetStateBorderSide.resolveWith((states) {
          // Match design system border width (0.75px) for consistency with text fields
          final color = baseDark.colorScheme.outlineVariant.withValues(alpha: 0.50);
          return BorderSide(color: color, width: 0.75);
        }),
        overlayColor: WidgetStatePropertyAll(baseDark.colorScheme.primary.withValues(alpha: 0.12)),
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
      builder: (context, child) {
        // Wrap with GestureDetector to dismiss keyboard on tap outside fields
        return GestureDetector(
          onTap: () {
            // Unfocus any active input field
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: child,
        );
      },
    );
  }
}
