import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // Legacy colors mapped to new branding palette to prevent breaking existing screens
  static const Color primaryColor = AppColors.primary;
  static const Color primaryDark = Color(0xFF0A1828); // Deeper Oxford Blue
  static const Color secondaryColor = AppColors.accent;
  static const Color darkSlate = AppColors.text;
  static const Color backgroundLight = AppColors.background;

  static const String fontFamily = 'Poppins';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.text,
        onSurface: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        centerTitle: false,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // sharper radius for classic look
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 2,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 3, // soft elevation
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // sharper corners for classic look
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text),
        headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text),
        titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
        bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, color: AppColors.text),
        bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, color: AppColors.text),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
        onPrimary: AppColors.white,
        onSecondary: AppColors.text,
        onSurface: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textDark,
        centerTitle: false,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 2,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
        headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, color: AppColors.textDark),
        bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  static BoxDecoration get primaryGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [primaryColor, primaryDark],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }
}
