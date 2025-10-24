// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController()..load();
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system);
  static const _prefsKey = 'settings_theme_mode_v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getInt(_prefsKey);
    if (code == null) {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.values[code.clamp(0, ThemeMode.values.length - 1)];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, mode.index);
  }
}
