import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    await prefs.setBool('has_user_selected_theme', true);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final hasUserSelected = prefs.getBool('has_user_selected_theme') ?? false;
    final bool isDark;
    if (hasUserSelected) {
      isDark = prefs.getBool('isDarkMode') ?? true;
    } else {
      // Default to Dark Mode
      isDark = true;
      await prefs.setBool('isDarkMode', true);
    }
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
