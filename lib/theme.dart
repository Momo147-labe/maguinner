import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuration des thèmes de l'application
/// Modernisé pour une apparence professionnelle et premium
class AppTheme {
  // --- PALETTE PROFESSIONNELLE ---
  // Indigo/Violet pour un look tech/moderne mais sérieux
  static const _seedColor = Color(0xFF4F46E5); // Indigo 600
  
  // Couleurs Dark Mode
  static const _darkPrimary = Color(0xFF818CF8); // Indigo 400
  static const _darkBackground = Color(0xFF0F172A); // Slate 900
  static const _darkSurface = Color(0xFF1E293B); // Slate 800
  static const _darkSurfaceVariant = Color(0xFF334155); // Slate 700

  // Couleurs Light Mode (plus doux)
  static const _lightPrimary = Color(0xFF4F46E5);
  static const _lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const _lightSurface = Colors.white;

  /// Thème clair professionnel
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      primary: _lightPrimary,
      secondary: const Color(0xFF0EA5E9), // Sky 500
      background: _lightBackground,
      surface: _lightSurface,
      surfaceTint: Colors.transparent, // Évite la teinte rose sur les surfaces
    ),
    scaffoldBackgroundColor: _lightBackground,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightPrimary, width: 2),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: _lightSurface,
      foregroundColor: const Color(0xFF1E293B),
      titleTextStyle: GoogleFonts.inter(
        color: const Color(0xFF1E293B),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF64748B)),
    ),
    dividerColor: Colors.grey.shade200,
  );

  /// Thème sombre professionnel
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimary,
      secondary: const Color(0xFF38BDF8), // Sky 400
      background: _darkBackground,
      surface: _darkSurface,
      onSurface: const Color(0xFFF1F5F9), // Slate 100
    ),
    scaffoldBackgroundColor: _darkBackground,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _darkSurfaceVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        side: const BorderSide(color: _darkPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkSurfaceVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkSurfaceVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkPrimary, width: 2),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: _darkBackground,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
    ),
    dividerColor: _darkSurfaceVariant,
    drawerTheme: const DrawerThemeData(
      backgroundColor: _darkBackground,
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF94A3B8),
    ),
  );
}