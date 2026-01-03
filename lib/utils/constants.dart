/// Constantes de l'application Gestion moderne de magasin
class AppConstants {
  
  // Informations de l'application
  static const String appName = 'Gestion moderne de magasin';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Application de gestion de magasin';
  
  // Base de données
  static const String databaseName = 'magasin.db';
  static const int databaseVersion = 1;
  
  // Utilisateur par défaut
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin123';
  static const String defaultUserFullName = 'Administrateur';
  static const String defaultUserRole = 'admin';
  
  // Paramètres UI
  static const double sidebarWidth = 250.0;
  static const double headerHeight = 60.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;
  
  // Couleurs
  static const int primaryColorValue = 0xFF2196F3;
  static const int secondaryColorValue = 0xFF03DAC6;
  static const int errorColorValue = 0xFFB00020;
  
  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String currencySymbol = '€';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 50;
  static const int maxProductNameLength = 100;
  static const int maxCustomerNameLength = 100;
  
  // Messages
  static const String loginErrorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
  static const String networkErrorMessage = 'Erreur de connexion réseau';
  static const String databaseErrorMessage = 'Erreur de base de données';
  static const String validationErrorMessage = 'Veuillez vérifier les données saisies';
  
  // Routes
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String productsRoute = '/products';
  static const String salesRoute = '/sales';
  static const String purchasesRoute = '/purchases';
  static const String inventoryRoute = '/inventory';
  static const String reportsRoute = '/reports';
  static const String usersRoute = '/users';
  
  // Catégories de produits par défaut
  static const List<String> defaultProductCategories = [
    'Épicerie',
    'Boulangerie',
    'Produits frais',
    'Boissons',
    'Hygiène',
    'Entretien',
    'Autres',
  ];
  
  // Rôles utilisateur
  static const List<String> userRoles = [
    'admin',
    'manager',
    'cashier',
    'stock_manager',
  ];
  
  // Paramètres d'export
  static const String exportDateFormat = 'yyyy-MM-dd_HH-mm-ss';
  static const String csvSeparator = ';';
  
  // Limites
  static const int maxItemsPerPage = 50;
  static const int defaultStockAlertThreshold = 5;
  static const double maxPrice = 999999.99;
  static const int maxQuantity = 999999;
  
  // Préférences utilisateur
  static const String themePreferenceKey = 'theme_mode';
  static const String languagePreferenceKey = 'language';
  static const String lastUserPreferenceKey = 'last_user';
  
  // Chemins de fichiers
  static const String backupDirectory = 'backups';
  static const String reportsDirectory = 'reports';
  static const String imagesDirectory = 'images';
  
  // Configuration de sécurité
  static const int sessionTimeoutMinutes = 60;
  static const int maxLoginAttempts = 3;
  static const int lockoutDurationMinutes = 15;
}