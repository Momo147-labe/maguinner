import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/database_helper.dart';
import 'theme.dart';
import 'services/theme_service.dart';
import 'services/license_service.dart';
import 'screens/login_screen.dart';
import 'screens/license_screen.dart';
import 'screens/first_launch_screen.dart';
import 'layouts/main_layout.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ OBLIGATOIRE pour Windows/Linux Desktop
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ✅ Force la création de la DB au démarrage
  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  Color _primaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final color = await ThemeService.getPrimaryColor();
    setState(() {
      _primaryColor = color;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  /// Résout la route initiale selon la RÈGLE PRINCIPALE
  Future<String> _resolveInitialRoute() async {
    try {
      // 🔒 RÈGLE PRINCIPALE : Vérifier si des utilisateurs existent
      final users = await DatabaseHelper.instance.getUsers();
      
      if (users.isNotEmpty) {
        // ✅ Utilisateurs existent → Login direct
        return '/login';
      } else {
        // ❌ Pas d'utilisateurs → Configuration initiale
        return '/first-launch';
      }
    } catch (e) {
      debugPrint('ROUTE RESOLUTION ERROR => $e');
      // 🔒 En cas d'erreur → Configuration initiale par défaut
      return '/first-launch';
    }
  }

  /// Vérifie si un utilisateur existe
  Future<bool> _hasUsers() async {
    try {
      final users = await DatabaseHelper.instance.getUsers();
      return users.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Vérifie si une licence valide existe
  Future<bool> _hasValidLicense() async {
    try {
      final settings = await DatabaseHelper.instance.getAppSettings();
      return settings != null && settings.license != null && settings.license!.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion moderne de magasins',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
          primary: _primaryColor,
        ),
        appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
          backgroundColor: _primaryColor,
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        colorScheme: AppTheme.darkTheme.colorScheme.copyWith(
          primary: _primaryColor,
        ),
        appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
          backgroundColor: _primaryColor,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      /// 🔒 LOGIQUE SIMPLE : VÉRIFICATION UTILISATEURS
      home: FutureBuilder<String>(
        future: _resolveInitialRoute(),
        builder: (context, snapshot) {
          // Loader pendant la vérification
          if (snapshot.connectionState != ConnectionState.done) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final route = snapshot.data ?? '/first-launch';
          
          switch (route) {
            case '/login':
              return const LoginScreen();
            case '/first-launch':
            default:
              // 🔒 PAR DÉFAUT : Configuration initiale
              return const FirstLaunchScreen();
          }
        },
      ),

      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final routeName = settings.name;

    switch (routeName) {
      case '/first-launch':
        return MaterialPageRoute(
          builder: (_) => const FirstLaunchScreen(),
        );
        
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case '/dashboard':
      case '/products':
      case '/clients':
      case '/suppliers':
      case '/sales':
      case '/purchases':
      case '/inventory':
      case '/reports':
      case '/store':
      case '/users':
        return _buildSecureRoute(settings, routeName!);

      case '/restart':
        return MaterialPageRoute(
          builder: (_) => const MyApp(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const FirstLaunchScreen(),
        );
    }
  }

  MaterialPageRoute _buildSecureRoute(
    RouteSettings settings,
    String routeName,
  ) {
    final args = settings.arguments;

    // 🔒 Sécurité : Vérifier utilisateur avant accès aux routes sécurisées
    if (args == null || args is! User) {
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      );
    }

    final user = args as User;

    return MaterialPageRoute(
      builder: (_) => MainLayout(
        currentUser: user,
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme,
        initialRoute: routeName,
      ),
    );
  }
}
