import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // 1. Change default to 'system' so it matches the OS by default
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Check the actual system brightness
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // 2. Add this method to support the Selection Dialog
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // (Optional) You can keep this for the quick toggle button if you still use it
  void toggleTheme() {
    if (_themeMode == ThemeMode.system) {
      // If currently system, switch to the opposite of the current system brightness
      final isSystemDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      _themeMode = isSystemDark ? ThemeMode.light : ThemeMode.dark;
    } else {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }
}
