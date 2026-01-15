import 'package:flutter/material.dart';

/// Utilitaire pour gérer la responsivité de l'application
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  /// Vérifie si l'écran est mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Vérifie si l'écran est tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Vérifie si l'écran est desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Retourne le nombre de colonnes pour une grille responsive
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 1;
    if (width < tabletBreakpoint) return 2;
    if (width < desktopBreakpoint) return 3;
    return 4;
  }

  /// Retourne le padding adaptatif
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(8);
    if (isTablet(context)) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  /// Retourne la taille de police adaptative
  static double getAdaptiveFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) return baseSize * 0.9;
    if (isTablet(context)) return baseSize * 0.95;
    return baseSize;
  }

  /// Retourne la hauteur adaptative pour les éléments
  static double getAdaptiveHeight(BuildContext context, double baseHeight) {
    if (isMobile(context)) return baseHeight * 0.8;
    if (isTablet(context)) return baseHeight * 0.9;
    return baseHeight;
  }

  /// Widget responsive qui adapte son contenu selon la taille d'écran
  static Widget responsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
}