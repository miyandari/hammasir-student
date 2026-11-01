import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تنظیمات سبک کاربر (فعلاً فقط حالت نمایش).
class SettingsStore {
  static const String _themeKey = 'theme_mode';

  Future<ThemeMode> readThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_themeKey)) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
      }
    } catch (_) {}
    return ThemeMode.system;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {}
  }
}
