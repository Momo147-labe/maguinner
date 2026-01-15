import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/store_info.dart';
import '../models/user.dart';
import '../core/database/database_helper.dart';

class StoreCreationPage extends StatefulWidget {
  final VoidCallback onStoreCreated;

  const StoreCreationPage({
    Key? key,
    required this.onStoreCreated,
  }) : super(key: key);

  @override
  State<StoreCreationPage> createState() => _StoreCreationPageState();
}

class _StoreCreationPageState extends State<StoreCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isCreating = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est obligatoire';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email est obligatoire';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe est obligatoire';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _adminPasswordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Créer les informations du magasin
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

      // Créer le compte administrateur avec mot de passe hashé
      final hashedPassword = sha256.convert(utf8.encode(_adminPasswordController.text)).toString();
      final adminUser = User(
        username: _adminUsernameController.text.trim(),
        password: hashedPassword,
        fullName: 'Administrateur',
        role: 'admin',
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.insertUser(adminUser);
      
      widget.onStoreCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Icon(Icons.business, size: 80, color: Colors.green.shade600),
              const SizedBox(height: 24),
              Text(
                'Configuration du Magasin',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Informations du magasin
              _buildSectionTitle('Informations du Magasin'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _storeNameController,
                label: 'Nom du magasin',
                icon: Icons.store,
                validator: (value) => _validateRequired(value, 'Nom du magasin'),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _ownerNameController,
                label: 'Nom du propriétaire',
                icon: Icons.person,
                validator: (value) => _validateRequired(value, 'Nom du propriétaire'),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone,
                validator: (value) => _validateRequired(value, 'Téléphone'),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _locationController,
                label: 'Lieu du magasin',
                icon: Icons.location_on,
                validator: (value) => _validateRequired(value, 'Lieu du magasin'),
              ),
              const SizedBox(height: 32),
              
              // Compte administrateur
              _buildSectionTitle('Compte Administrateur'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _adminUsernameController,
                label: 'Nom d\'utilisateur',
                icon: Icons.account_circle,
                validator: (value) => _validateRequired(value, 'Nom d\'utilisateur'),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _adminPasswordController,
                label: 'Mot de passe',
                icon: Icons.lock,
                obscureText: _obscurePassword,
                validator: _validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirmer le mot de passe',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Terminer la Configuration',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label *',
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }
}