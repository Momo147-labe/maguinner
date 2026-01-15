import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/database/database_helper.dart';
import '../models/store_info.dart';
import '../services/license_service.dart';
import 'password_reset_screen.dart';

/// Écran de connexion moderne et professionnel
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  StoreInfo? _storeInfo;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );
    _animationController.forward();
  }

  Future<void> _loadStoreInfo() async {
    try {
      final store = await DatabaseHelper.instance.getStoreInfo();
      setState(() => _storeInfo = store);
    } catch (e) {
      // Ignorer l'erreur si pas de magasin configuré
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await DatabaseHelper.instance.getUserByUsername(
        _usernameController.text.trim(),
      );

      // Hacher le mot de passe saisi pour comparaison
      final hashedPassword = sha256
          .convert(utf8.encode(_passwordController.text))
          .toString();

      if (user != null && user.password == hashedPassword) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacementNamed('/dashboard', arguments: user);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text('Nom d\'utilisateur ou mot de passe incorrect'),
                  ),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur de connexion: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainer,
                  ]
                : [
                    theme.colorScheme.primaryContainer.withOpacity(0.3),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: isMobile ? double.infinity : 450,
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 450,
                    ),
                    child: Card(
                      elevation: 8,
                      shadowColor: theme.shadowColor.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: theme.cardTheme.color,
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 24 : 40),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo avec animation
                                Container(
                                  width: isMobile ? 64 : 80,
                                  height: isMobile ? 64 : 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.tertiary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 20 : 24,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.store_rounded,
                                    size: isMobile ? 32 : 40,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 20 : 32),

                                // Titre principal
                                Text(
                                  _storeInfo?.name ?? 'Gestion Magasin',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                        fontSize: isMobile ? 20 : 24,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Connectez-vous pour continuer',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isMobile ? 32 : 48),

                                // Champ nom d'utilisateur
                                TextFormField(
                                  controller: _usernameController,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: 'Nom d\'utilisateur',
                                    hintText: 'Entrez votre identifiant',
                                    prefixIcon: Icon(
                                      Icons.person_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme
                                        .surfaceContainerLowest,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez saisir votre nom d\'utilisateur';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isMobile ? 16 : 24),

                                // Champ mot de passe
                                TextFormField(
                                  controller: _passwordController,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: 'Mot de passe',
                                    hintText: 'Entrez votre mot de passe',
                                    prefixIcon: Icon(
                                      Icons.lock_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        );
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme
                                        .surfaceContainerLowest,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez saisir votre mot de passe';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _login(),
                                ),
                                SizedBox(height: isMobile ? 24 : 32),

                                // Bouton de connexion
                                SizedBox(
                                  width: double.infinity,
                                  height: isMobile ? 50 : 56,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: isMobile ? 20 : 24,
                                            height: isMobile ? 20 : 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    theme.colorScheme.onPrimary,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Se connecter',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimary,
                                                ),
                                          ),
                                  ),
                                ),

                                SizedBox(height: isMobile ? 16 : 24),

                                // Lien mot de passe oublié
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PasswordResetScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Mot de passe oublié ?'),
                                ),

                                // Informations de connexion
                                if (_storeInfo == null) ...[
                                  SizedBox(height: isMobile ? 16 : 24),
                                  Container(
                                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: isMobile ? 16 : 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Utilisez le compte administrateur par défaut si c\'est votre première connexion.',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
