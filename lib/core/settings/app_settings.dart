import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centraliza configuraciones globales de la app (como el modo oscuro).
class AppSettings {
  AppSettings._internal();

  static final AppSettings instance = AppSettings._internal();
  static const _darkModeKey = 'settings.dark_mode_enabled';

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final isDarkEnabled = prefs.getBool(_darkModeKey) ?? false;
    themeModeNotifier.value = isDarkEnabled ? ThemeMode.dark : ThemeMode.light;
    _initialized = true;
  }

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  Future<void> setDarkMode(bool enabled) async {
    themeModeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }
}
