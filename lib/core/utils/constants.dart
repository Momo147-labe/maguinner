import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales - Design Windows moderne
  static const Color primary = Color(0xFF0078D4);
  static const Color primaryContainer = Color(0xFFE3F2FD);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF001D35);
  
  // Couleurs de surface
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  
  // Couleurs de fond
  static const Color background = Color(0xFFFAFAFA);
  static const Color onBackground = Color(0xFF1C1B1F);
  
  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Couleurs neutres
  static const Color outline = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  
  // Sidebar
  static const Color sidebarBackground = Color(0xFF2D3748);
  static const Color sidebarSelected = Color(0xFF4A5568);
  static const Color sidebarText = Colors.white;
}

class AppSizes {
  // Espacements
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Rayons de bordure
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  
  // Tailles d'icônes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  
  // Sidebar
  static const double sidebarWidth = 280.0;
  static const double sidebarCollapsedWidth = 72.0;
  
  // Header
  static const double headerHeight = 64.0;
}

class AppStrings {
  // App
  static const String appName = 'Gestion Magasin Pro';
  static const String version = '1.0.0';
  
  // Auth
  static const String login = 'Connexion';
  static const String logout = 'Déconnexion';
  static const String username = 'Nom d\'utilisateur';
  static const String password = 'Mot de passe';
  
  // Navigation
  static const String dashboard = 'Tableau de bord';
  static const String products = 'Produits';
  static const String sales = 'Ventes';
  static const String purchases = 'Achats';
  static const String customers = 'Clients';
  static const String suppliers = 'Fournisseurs';
  static const String reports = 'Rapports';
  static const String users = 'Utilisateurs';
  static const String settings = 'Paramètres';
  
  // Actions
  static const String add = 'Ajouter';
  static const String edit = 'Modifier';
  static const String delete = 'Supprimer';
  static const String save = 'Enregistrer';
  static const String cancel = 'Annuler';
  static const String search = 'Rechercher';
  static const String filter = 'Filtrer';
  static const String export = 'Exporter';
  static const String print = 'Imprimer';
  
  // Messages
  static const String loading = 'Chargement...';
  static const String noData = 'Aucune donnée disponible';
  static const String error = 'Une erreur s\'est produite';
  static const String success = 'Opération réussie';
  
  // Currency
  static const String currency = 'GNF';
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurface,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurface,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurfaceVariant,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );
}