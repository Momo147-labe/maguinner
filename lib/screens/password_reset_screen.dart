import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/database/database_helper.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _secretCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _secretCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Rechercher l'utilisateur par nom d'utilisateur ou email
      final user = await DatabaseHelper.instance.getUserByUsernameOrEmail(
        _identifierController.text.trim(),
      );

      if (user == null) {
        _showError('Utilisateur non trouvé');
        return;
      }

      // Vérifier le code secret
      final hashedSecretCode = sha256.convert(utf8.encode(_secretCodeController.text)).toString();
      
      if (user.secretCode == null || user.secretCode != hashedSecretCode) {
        _showError('Code secret incorrect');
        return;
      }

      // Mettre à jour le mot de passe
      final hashedNewPassword = sha256.convert(utf8.encode(_newPasswordController.text)).toString();
      await DatabaseHelper.instance.updateUserPassword(user.id!, hashedNewPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe réinitialisé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réinitialiser le mot de passe'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_reset,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Réinitialisation du mot de passe',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    TextFormField(
                      controller: _identifierController,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'utilisateur ou email',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return 'Champ requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _secretCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Code secret',
                        prefixIcon: Icon(Icons.security),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return 'Code secret requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: _obscureNewPassword,
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return 'Nouveau mot de passe requis';
                        }
                        if (value!.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return 'Confirmation requise';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Réinitialiser le mot de passe'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}