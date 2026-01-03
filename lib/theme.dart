import 'package:flutter/material.dart';

/// Configuration des thèmes de l'application
class AppTheme {
  // Couleurs pour le dark mode professionnel
  static const Color _darkPrimary = Color(0xFF6366F1);
  static const Color _darkSecondary = Color(0xFF8B5CF6);
  static const Color _darkSurface = Color(0xFF1F2937);
  static const Color _darkBackground = Color(0xFF111827);
  static const Color _darkCard = Color(0xFF374151);
  
  /// Thème clair
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.light,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
  );

  /// Thème sombre professionnel
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimary,
      secondary: _darkSecondary,
      surface: _darkSurface,
      background: _darkBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFE5E7EB),
      onBackground: const Color(0xFFE5E7EB),
      outline: const Color(0xFF6B7280),
    ),
    scaffoldBackgroundColor: _darkBackground,
    cardColor: _darkCard,
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: const Color(0xFFE5E7EB),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        side: BorderSide(color: _darkPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6B7280)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6B7280)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkPrimary),
      ),
    ),
    dividerColor: const Color(0xFF374151),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE5E7EB)),
      bodyMedium: TextStyle(color: Color(0xFFE5E7EB)),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
      headlineLarge: TextStyle(color: Color(0xFFE5E7EB)),
      headlineMedium: TextStyle(color: Color(0xFFE5E7EB)),
      headlineSmall: TextStyle(color: Color(0xFFE5E7EB)),
      titleLarge: TextStyle(color: Color(0xFFE5E7EB)),
      titleMedium: TextStyle(color: Color(0xFFE5E7EB)),
      titleSmall: TextStyle(color: Color(0xFFE5E7EB)),
    ),
  );
}