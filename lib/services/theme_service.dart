import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _colorKey = 'app_primary_color';
  
  /// Couleurs prédéfinies disponibles
  static const List<Color> availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.deepOrange,
    Colors.cyan,
    Colors.lime,
  ];

  /// Sauvegarde la couleur sélectionnée
  static Future<void> savePrimaryColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
  }

  /// Récupère la couleur sauvegardée
  static Future<Color> getPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_colorKey);
    if (colorValue != null) {
      return Color(colorValue);
    }
    return Colors.blue; // Couleur par défaut
  }

  /// Génère un thème avec la couleur primaire
  static ThemeData generateTheme(Color primaryColor, bool isDark) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(primaryColor),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(primaryColor),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(primaryColor),
      ),
    );
  }

  /// Obtient le nom de la couleur
  static String getColorName(Color color) {
    if (color == Colors.blue) return 'Bleu';
    if (color == Colors.green) return 'Vert';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Violet';
    if (color == Colors.red) return 'Rouge';
    if (color == Colors.teal) return 'Sarcelle';
    if (color == Colors.indigo) return 'Indigo';
    if (color == Colors.pink) return 'Rose';
    if (color == Colors.amber) return 'Ambre';
    if (color == Colors.deepOrange) return 'Orange Foncé';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.lime) return 'Citron Vert';
    return 'Personnalisé';
  }
}