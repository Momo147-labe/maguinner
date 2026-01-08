import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/database/database_helper.dart';
import '../models/store_info.dart';
import '../models/user.dart';
import '../services/license_service.dart';

/// 🎆 Flux de premier lancement - 6 pages
class FirstLaunchScreen extends StatefulWidget {
  const FirstLaunchScreen({super.key});

  @override
  State<FirstLaunchScreen> createState() => _FirstLaunchScreenState();
}

class _FirstLaunchScreenState extends State<FirstLaunchScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  
  // Contrôleurs pour la page licence
  final _licenseController = TextEditingController();
  String? _licenseError;
  
  // Contrôleurs pour la page magasin + utilisateur
  final _storeNameController = TextEditingController();
  final _storeOwnerController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _userNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secretCodeController = TextEditingController();
  String? _setupError;

  @override
  void dispose() {
    _pageController.dispose();
    _licenseController.dispose();
    _storeNameController.dispose();
    _storeOwnerController.dispose();
    _storePhoneController.dispose();
    _storeAddressController.dispose();
    _userNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _activateLicense() async {
    final licenseKey = _licenseController.text.trim();
    
    if (licenseKey.isEmpty) {
      setState(() => _licenseError = 'Veuillez saisir une clé de licence');
      return;
    }

    setState(() {
      _isLoading = true;
      _licenseError = null;
    });

    try {
      final result = await LicenseService.activate(licenseKey);
      
      if (result.isSuccess) {
        // ✅ Licence activée et sauvée → Page suivante
        _nextPage();
      } else {
        setState(() => _licenseError = result.message);
      }
    } catch (e) {
      setState(() => _licenseError = 'Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSetup() async {
    // Validation des champs (adresse optionnelle)
    if (_storeNameController.text.trim().isEmpty ||
        _storeOwnerController.text.trim().isEmpty ||
        _storePhoneController.text.trim().isEmpty ||
        _userNameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _secretCodeController.text.trim().isEmpty) {
      setState(() => _setupError = 'Les champs marqués * sont obligatoires');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _setupError = 'Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() {
      _isLoading = true;
      _setupError = null;
    });

    try {
      // Vérifier si username existe déjà
      final existingUser = await DatabaseHelper.instance.getUserByUsername(_usernameController.text.trim());
      if (existingUser != null) {
        setState(() => _setupError = 'Ce nom d\'utilisateur existe déjà');
        return;
      }

      // 🏪 Créer/Remplacer le magasin (UN SEUL)
      final storeInfo = StoreInfo(
        id: 1, // Toujours ID 1
        name: _storeNameController.text.trim(),
        ownerName: _storeOwnerController.text.trim(),
        phone: _storePhoneController.text.trim(),
        email: '', // Optionnel
        location: _storeAddressController.text.trim().isEmpty 
            ? 'Non spécifiée' 
            : _storeAddressController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );
      
      await DatabaseHelper.instance.updateStoreInfo(storeInfo); // UPDATE, pas INSERT

      // 👤 Créer le premier utilisateur ADMIN
      final hashedPassword = sha256.convert(utf8.encode(_passwordController.text)).toString();
      final hashedSecretCode = sha256.convert(utf8.encode(_secretCodeController.text)).toString();
      
      final user = User(
        username: _usernameController.text.trim(),
        password: hashedPassword,
        fullName: _userNameController.text.trim(),
        role: 'admin',
        secretCode: hashedSecretCode,
        createdAt: DateTime.now().toIso8601String(),
      );
      
      await DatabaseHelper.instance.insertUser(user);

      // ✅ Setup terminé → Login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      setState(() => _setupError = 'Erreur lors de la création: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barre de progression
          Container(
            height: 80,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Configuration initiale',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_currentPage + 1}/6',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu des pages
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildPresentationPage(
                  title: 'Bienvenue',
                  subtitle: 'Gestion moderne de magasin',
                  description: 'Une solution complète pour gérer votre magasin efficacement',
                  icon: Icons.store,
                ),
                _buildPresentationPage(
                  title: 'Gestion des stocks',
                  subtitle: 'Inventaire en temps réel',
                  description: 'Suivez vos produits, gérez les stocks et recevez des alertes',
                  icon: Icons.inventory,
                ),
                _buildPresentationPage(
                  title: 'Ventes & Achats',
                  subtitle: 'Transactions simplifiées',
                  description: 'Enregistrez vos ventes et achats avec facilité',
                  icon: Icons.point_of_sale,
                ),
                _buildPresentationPage(
                  title: 'Rapports détaillés',
                  subtitle: 'Analyses et statistiques',
                  description: 'Obtenez des insights précieux sur votre activité',
                  icon: Icons.analytics,
                ),
                _buildLicensePage(),
                _buildSetupPage(),
              ],
            ),
          ),
          
          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0 && _currentPage < 4)
                  TextButton(
                    onPressed: _previousPage,
                    child: const Text('Précédent'),
                  )
                else
                  const SizedBox(width: 80),
                
                if (_currentPage < 4)
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: const Text('Suivant'),
                  )
                else
                  const SizedBox(width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationPage({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              icon,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLicensePage() {
    return Center(
      child: Container(
        width: 500,
        margin: const EdgeInsets.all(40),
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône professionnelle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Titre
                Text(
                  'Activation de la licence',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Sous-titre
                Text(
                  'Activez votre application pour continuer',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Champ licence
                TextField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: 'Clé de licence',
                    hintText: 'LIC-XXXXXXXXXXXX-XXXXXXXXXXXXXXXX',
                    prefixIcon: Icon(
                      Icons.vpn_key,
                      color: Theme.of(context).primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    errorText: _licenseError,
                    errorMaxLines: 2,
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Bouton activation
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _activateLicense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Activation en cours...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'ACTIVER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
                
                // Message de sécurité
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre licence est vérifiée de manière sécurisée',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupPage() {
    return Center(
      child: Container(
        width: 800,
        margin: const EdgeInsets.all(40),
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre principal
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.store,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Configuration finale',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre magasin et votre compte administrateur',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Cards en row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Magasin
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.store,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Informations du magasin',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              TextField(
                                controller: _storeNameController,
                                decoration: InputDecoration(
                                  labelText: 'Nom du magasin *',
                                  hintText: 'Ex: Boutique Centrale',
                                  prefixIcon: const Icon(Icons.business),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextField(
                                controller: _storeOwnerController,
                                decoration: InputDecoration(
                                  labelText: 'Propriétaire *',
                                  hintText: 'Ex: Mamadou Diallo',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextField(
                                controller: _storePhoneController,
                                decoration: InputDecoration(
                                  labelText: 'Téléphone *',
                                  hintText: 'Ex: +224 123 456 789',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextField(
                                controller: _storeAddressController,
                                decoration: InputDecoration(
                                  labelText: 'Adresse / Ville',
                                  hintText: 'Ex: Conakry, Guinée (optionnel)',
                                  prefixIcon: const Icon(Icons.location_on),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              
                              // Devise fixée
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.monetization_on, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Devise: GNF (Franc guinéen)',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 24),
                      
                      // Section Utilisateur
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.orange[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Premier administrateur',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              TextField(
                                controller: _userNameController,
                                decoration: InputDecoration(
                                  labelText: 'Nom complet *',
                                  hintText: 'Ex: Mamadou Diallo',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Nom d\'utilisateur *',
                                  hintText: 'Ex: admin',
                                  prefixIcon: const Icon(Icons.account_circle),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe *',
                                  hintText: 'Minimum 6 caractères',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 16),
                              
                              TextField(
                                controller: _secretCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Code secret *',
                                  hintText: 'Pour récupération',
                                  prefixIcon: const Icon(Icons.security),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                obscureText: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Message d'erreur
                  if (_setupError != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _setupError!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Bouton final
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Configuration en cours...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'FINALISER LA CONFIGURATION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}