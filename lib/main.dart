import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/database_helper.dart';
import 'theme.dart';
import 'services/theme_service.dart';
import 'screens/login_screen.dart';
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

  /// Vérifie si le premier lancement a été fait
  Future<bool> _isFirstLaunch() async {
    try {
      final settings = await DatabaseHelper.instance.getAppSettings();
      return settings == null || !settings.firstLaunchDone;
    } catch (_) {
      return true; // Premier lancement par défaut
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

      /// ✅ NOUVELLE LOGIQUE 100% OFFLINE
      home: FutureBuilder<List<bool>>(
        future: Future.wait([_isFirstLaunch(), _hasUsers()]),
        builder: (context, snapshot) {
          // Loader simple pendant la vérification SQLite
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final isFirstLaunch = snapshot.data?[0] ?? true;
          final hasUsers = snapshot.data?[1] ?? false;

          // Premier lancement → Onboarding
          if (isFirstLaunch) {
            return const FirstLaunchScreen();
          }

          // Utilisateur existe → Login
          if (hasUsers) {
            return const LoginScreen();
          }

          // Sinon → Onboarding (sécurité)
          return const FirstLaunchScreen();
        },
      ),

      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final routeName = settings.name;

    switch (routeName) {
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
        // Route spéciale pour redémarrer l'app après changement de couleur
        return MaterialPageRoute(
          builder: (_) => const MyApp(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
    }
  }

  MaterialPageRoute _buildSecureRoute(
    RouteSettings settings,
    String routeName,
  ) {
    final args = settings.arguments;

    // Sécurité : pas d'utilisateur → login
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
