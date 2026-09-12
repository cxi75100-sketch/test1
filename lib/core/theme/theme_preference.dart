import 'package:flutter/material.dart';

const themeModeSettingKey = 'theme_mode';

enum ThemePreference {
  system('system', '跟随系统', Icons.brightness_auto_rounded),
  light('light', '日间', Icons.light_mode_rounded),
  dark('dark', '夜间', Icons.dark_mode_rounded);

  const ThemePreference(this.storageValue, this.label, this.icon);

  final String storageValue;
  final String label;
  final IconData icon;

  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  static ThemePreference fromSettings(Map<String, String> settings) {
    final value = settings[themeModeSettingKey];
    return ThemePreference.values.firstWhere(
      (preference) => preference.storageValue == value,
      orElse: () => ThemePreference.system,
    );
  }
}
