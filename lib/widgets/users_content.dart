import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import '../core/database/database_helper.dart';
import '../utils/responsive_helper.dart';

/// Gestion des utilisateurs avec rôles et sécurité
class UsersContent extends StatefulWidget {
  final User currentUser;

  const UsersContent({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<UsersContent> {
  List<User> _users = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _secretCodeController = TextEditingController();
  String _selectedRole = 'caissier';

  final List<String> _roles = ['admin', 'gestionnaire', 'caissier', 'vendeur'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await DatabaseHelper.instance.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      // Vérifier si l'utilisateur existe déjà
      final existingUser = await DatabaseHelper.instance.getUserByUsername(
        _usernameController.text.trim(),
      );
      if (!mounted) return;

      if (existingUser != null) {
        setState(() {
          _error = 'Ce nom d\'utilisateur existe déjà';
          _isCreating = false;
        });
        return;
      }

      // Créer l'utilisateur
      final hashedPassword = sha256
          .convert(utf8.encode(_passwordController.text))
          .toString();
      final hashedSecretCode = sha256
          .convert(utf8.encode(_secretCodeController.text.trim()))
          .toString();
      final newUser = User(
        username: _usernameController.text.trim(),
        password: hashedPassword,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        secretCode: hashedSecretCode,
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.insertUser(newUser);

      if (mounted) {
        setState(() => _isCreating = false);
        Navigator.of(context).pop();
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de la création: $e';
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    if (user.id == widget.currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas supprimer votre propre compte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'utilisateur "${user.username}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteUser(user.id!);
        if (!mounted) return;
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCreateUserDialog() {
    _usernameController.clear();
    _passwordController.clear();
    _fullNameController.clear();
    _secretCodeController.clear();
    _selectedRole = 'caissier';
    _error = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Dialog(
            backgroundColor: theme.cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_add_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Nouvel Utilisateur',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Nom d\'utilisateur obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Nom complet obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Rôle',
                        prefixIcon: const Icon(
                          Icons.admin_panel_settings_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      items: _roles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(_getRoleDisplayName(role)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedRole = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mot de passe minimum 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _secretCodeController,
                      decoration: InputDecoration(
                        labelText: 'Code secret (réinitialisation)',
                        prefixIcon: const Icon(Icons.security_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Code secret obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isCreating
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: _isCreating
                              ? null
                              : () {
                                  setDialogState(() {});
                                  _createUser();
                                },
                          icon: _isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_isCreating ? 'Création...' : 'Créer'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'gestionnaire':
        return 'Gestionnaire';
      case 'caissier':
        return 'Caissier';
      case 'vendeur':
        return 'Vendeur';
      default:
        return role;
    }
  }

  MaterialColor _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'gestionnaire':
        return Colors.blue;
      case 'caissier':
        return Colors.green;
      case 'vendeur':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = ResponsiveHelper.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(isMobile),
          SizedBox(height: isMobile ? 16 : 24),

          // Liste des utilisateurs
          _buildUsersList(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Utilisateurs',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Gérez les comptes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.currentUser.role == 'admin')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nouvel utilisateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.people,
            color: Colors.blue.shade700,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des Utilisateurs',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Créez et gérez les comptes utilisateurs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (widget.currentUser.role == 'admin')
          ElevatedButton.icon(
            onPressed: _showCreateUserDialog,
            icon: const Icon(Icons.add),
            label: const Text('Nouvel utilisateur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildUsersList(bool isMobile) {
    if (isMobile) {
      return Column(
        children: _users.map((user) => _buildMobileUserCard(user)).toList(),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utilisateurs (${_users.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_users.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Aucun utilisateur trouvé'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isCurrentUser = user.id == widget.currentUser.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(
                        user.role ?? 'vendeur',
                      ).shade100,
                      child: Icon(
                        Icons.person,
                        color: _getRoleColor(
                          user.role ?? 'vendeur',
                        ).shade700,
                      ),
                    ),
                    title: Text(
                      user.fullName ?? user.username,
                      style: TextStyle(
                        fontWeight: isCurrentUser
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@${user.username}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                  user.role ?? 'vendeur',
                                ).shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRoleDisplayName(
                                  user.role ?? 'vendeur',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getRoleColor(
                                    user.role ?? 'vendeur',
                                  ).shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Vous',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing:
                        widget.currentUser.role == 'admin' &&
                            !isCurrentUser
                        ? IconButton(
                            onPressed: () => _deleteUser(user),
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            tooltip: 'Supprimer l\'utilisateur',
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileUserCard(User user) {
    final isCurrentUser = user.id == widget.currentUser.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(
                    user.role ?? 'vendeur',
                  ).shade100,
                  child: Icon(
                    Icons.person,
                    color: _getRoleColor(
                      user.role ?? 'vendeur',
                    ).shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? user.username,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.currentUser.role == 'admin' && !isCurrentUser)
                  IconButton(
                    onPressed: () => _deleteUser(user),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    tooltip: 'Supprimer',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(
                      user.role ?? 'vendeur',
                    ).shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getRoleDisplayName(
                      user.role ?? 'vendeur',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: _getRoleColor(
                        user.role ?? 'vendeur',
                      ).shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Vous',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
