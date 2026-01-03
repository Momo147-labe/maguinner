import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/app_settings.dart';
import '../models/store_info.dart';
import '../models/user.dart';
import '../core/database/database_helper.dart';

class FirstLaunchScreen extends StatefulWidget {
  const FirstLaunchScreen({Key? key}) : super(key: key);

  @override
  State<FirstLaunchScreen> createState() => _FirstLaunchScreenState();
}

class _FirstLaunchScreenState extends State<FirstLaunchScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Store form
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _adminFullNameController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _secretCodeController = TextEditingController();
  
  bool _isCreatingStore = false;
  String? _storeError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _adminFullNameController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _confirmPasswordController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) { // 6 pages (0-5)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }



  Future<void> _createStoreAndAdmin() async {
    // Validation des champs
    if (_storeNameController.text.trim().isEmpty) {
      setState(() => _storeError = 'Nom du magasin obligatoire');
      return;
    }
    if (_ownerNameController.text.trim().isEmpty) {
      setState(() => _storeError = 'Nom du propriétaire obligatoire');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _storeError = 'Téléphone obligatoire');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _storeError = 'Email obligatoire');
      return;
    }
    // Validation email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      setState(() => _storeError = 'Email invalide');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      setState(() => _storeError = 'Localisation obligatoire');
      return;
    }
    if (_adminFullNameController.text.trim().isEmpty) {
      setState(() => _storeError = 'Nom complet administrateur obligatoire');
      return;
    }
    if (_adminUsernameController.text.trim().isEmpty) {
      setState(() => _storeError = 'Nom d\'utilisateur obligatoire');
      return;
    }
    if (_adminPasswordController.text.length < 8) {
      setState(() => _storeError = 'Mot de passe minimum 8 caractères');
      return;
    }
    if (_adminPasswordController.text != _confirmPasswordController.text) {
      setState(() => _storeError = 'Les mots de passe ne correspondent pas');
      return;
    }
    if (_secretCodeController.text.trim().isEmpty) {
      setState(() => _storeError = 'Code secret obligatoire');
      return;
    }

    setState(() {
      _isCreatingStore = true;
      _storeError = null;
    });

    try {
      // 1. Vérifier si l'utilisateur existe déjà
      final existingUser = await DatabaseHelper.instance.getUserByUsername(_adminUsernameController.text.trim());
      if (existingUser != null) {
        setState(() {
          _storeError = 'Ce nom d\'utilisateur existe déjà';
          _isCreatingStore = false;
        });
        return;
      }

      // 2. Créer les informations du magasin
      final storeInfo = StoreInfo(
        name: _storeNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        location: _locationController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.insertStoreInfo(storeInfo);

      // 3. Créer le compte administrateur
      final hashedPassword = sha256.convert(utf8.encode(_adminPasswordController.text)).toString();
      final hashedSecretCode = sha256.convert(utf8.encode(_secretCodeController.text.trim())).toString();
      final adminUser = User(
        username: _adminUsernameController.text.trim(),
        password: hashedPassword,
        fullName: _adminFullNameController.text.trim(),
        role: 'admin',
        secretCode: hashedSecretCode,
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.insertUser(adminUser);

      // 4. Marquer le premier lancement comme terminé
      await DatabaseHelper.instance.markFirstLaunchDone();

      // 5. Rediriger vers login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() {
        _storeError = 'Erreur lors de la création du compte';
        _isCreatingStore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header avec logo et titre
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.store, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestion moderne de magasin',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            'Configuration initiale',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Barre de progression améliorée
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Étape ${_currentPage + 1} sur 6',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${((_currentPage + 1) / 6 * 100).round()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_currentPage + 1) / 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Pages
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                    _animationController.reset();
                    _animationController.forward();
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildFeaturesPage(),
                    _buildBenefitsPage(),
                    _buildTutorialPage(),
                    _buildSecurityPage(),
                    _buildStoreCreationPage(),
                  ],
                ),
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    OutlinedButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Précédent'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    )
                  else
                    const SizedBox(),
                  
                  if (_currentPage < 5)
                    ElevatedButton.icon(
                      onPressed: _nextPage,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Suivant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isCreatingStore ? null : _createStoreAndAdmin,
                      icon: _isCreatingStore 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: Text(_isCreatingStore ? 'Création...' : 'Terminer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.store, size: 80, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 40),
          Text(
            'Bienvenue dans Gestion moderne de magasin',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Votre solution complète de gestion de magasin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Gérez facilement vos produits, clients, fournisseurs, ventes et achats en un seul endroit. Une interface moderne et intuitive pour optimiser votre business.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.featured_play_list, size: 80, color: Colors.indigo.shade700),
          ),
          const SizedBox(height: 30),
          Text(
            'Fonctionnalités Principales',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildFeatureCard(Icons.inventory_2, 'Gestion des Produits', 'Ajoutez, modifiez et suivez vos produits avec codes-barres', Colors.blue),
          _buildFeatureCard(Icons.people, 'Gestion des Clients', 'Base de données clients complète avec historique', Colors.green),
          _buildFeatureCard(Icons.business, 'Gestion des Fournisseurs', 'Suivez vos relations fournisseurs et commandes', Colors.orange),
          _buildFeatureCard(Icons.point_of_sale, 'Point de Vente', 'Interface de vente rapide et intuitive', Colors.purple),
          _buildFeatureCard(Icons.analytics, 'Rapports et Analyses', 'Tableaux de bord et statistiques détaillées', Colors.teal),
        ],
      ),
    );
  }

  Widget _buildBenefitsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.trending_up, size: 80, color: Colors.green.shade700),
          ),
          const SizedBox(height: 30),
          Text(
            'Avantages Business',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildBenefitCard('💰', 'Augmentez vos profits', 'Optimisez vos marges et réduisez les pertes grâce aux analyses précises'),
          _buildBenefitCard('⏱️', 'Gagnez du temps', 'Automatisez vos tâches répétitives et accélérez vos processus'),
          _buildBenefitCard('📊', 'Prenez de meilleures décisions', 'Basées sur des données précises et des rapports détaillés'),
          _buildBenefitCard('🔒', 'Sécurisé et fiable', 'Vos données sont protégées et sauvegardées localement'),
        ],
      ),
    );
  }

  Widget _buildTutorialPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.school, size: 80, color: Colors.purple.shade700),
          ),
          const SizedBox(height: 30),
          Text(
            'Comment commencer',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildStepCard('1', 'Configurez votre magasin', 'Entrez les informations de base de votre établissement', Colors.blue),
          _buildStepCard('2', 'Créez votre compte admin', 'Définissez vos identifiants de connexion sécurisés', Colors.green),
          _buildStepCard('3', 'Commencez à utiliser', 'Ajoutez vos premiers produits et commencez à vendre', Colors.purple),
        ],
      ),
    );
  }



  Widget _buildStoreCreationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.store_mall_directory, size: 80, color: Colors.green.shade700),
          ),
          const SizedBox(height: 30),
          Text(
            'Configuration du Magasin',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          if (_storeError != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _storeError!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Informations du magasin
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations du Magasin',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_storeNameController, 'Nom du magasin', Icons.store),
                      const SizedBox(height: 16),
                      _buildTextField(_ownerNameController, 'Nom du propriétaire', Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Téléphone', Icons.phone),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Email', Icons.email),
                      const SizedBox(height: 16),
                      _buildTextField(_locationController, 'Lieu du magasin', Icons.location_on),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Compte administrateur
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compte Administrateur',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_adminFullNameController, 'Nom complet de l\'administrateur', Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(_adminUsernameController, 'Nom d\'utilisateur admin', Icons.admin_panel_settings),
                      const SizedBox(height: 16),
                      _buildTextField(_adminPasswordController, 'Mot de passe', Icons.lock, isPassword: true),
                      const SizedBox(height: 16),
                      _buildTextField(_confirmPasswordController, 'Confirmer le mot de passe', Icons.lock_outline, isPassword: true),
                      const SizedBox(height: 16),
                      _buildTextField(_secretCodeController, 'Code secret (pour réinitialisation)', Icons.security, isPassword: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.security, size: 80, color: Colors.orange.shade700),
          ),
          const SizedBox(height: 30),
          Text(
            'Sécurité et Confidentialité',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildSecurityCard('🔒', 'Données 100% locales', 'Toutes vos données sont stockées localement sur votre appareil'),
          _buildSecurityCard('🚫', 'Aucune connexion Internet requise', 'L\'application fonctionne complètement hors ligne'),
          _buildSecurityCard('🔐', 'Chiffrement des mots de passe', 'Vos mots de passe sont sécurisés avec un chiffrement avancé'),
          _buildSecurityCard('📊', 'Sauvegarde locale', 'Vos données sont automatiquement sauvegardées dans la base SQLite'),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(String emoji, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      obscureText: isPassword,
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: color.shade700),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(String emoji, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String description, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.shade600,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}