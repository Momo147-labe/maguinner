import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/custom_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';

/// Écran de gestion des utilisateurs
class UsersScreen extends StatefulWidget {
  final User currentUser;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const UsersScreen({
    Key? key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await DatabaseHelper.instance.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _onNavigate(String route) {
    if (route == '/login') {
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      Navigator.of(context).pushNamed(route, arguments: widget.currentUser);
    }
  }

  void _showUserDialog([User? user]) {
    showDialog(
      context: context,
      builder: (context) => UserDialog(
        user: user,
        onSave: (savedUser) async {
          try {
            if (user == null) {
              await DatabaseHelper.instance.insertUser(savedUser);
            } else {
              await DatabaseHelper.instance.updateUser(savedUser);
            }
            _loadUsers();
            Navigator.of(context).pop();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteUser(int index) async {
    final user = _users[index];
    if (user.id == widget.currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer votre propre compte')),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.deleteUser(user.id!);
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentRoute: '/users',
            onNavigate: _onNavigate,
          ),
          Expanded(
            child: Column(
              children: [
                Header(
                  userName: widget.currentUser.fullName ?? widget.currentUser.username,
                  isDarkMode: widget.isDarkMode,
                  onThemeToggle: widget.onThemeToggle,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomDataTable(
                          title: 'Gestion des Utilisateurs',
                          columns: const [
                            'ID',
                            'Nom d\'utilisateur',
                            'Nom complet',
                            'Rôle',
                            'Date de création',
                          ],
                          rows: _users.map((user) => [
                            user.id.toString(),
                            user.username,
                            user.fullName ?? '',
                            user.role ?? '',
                            user.createdAt ?? '',
                          ]).toList(),
                          onAdd: () => _showUserDialog(),
                          onEdit: List.generate(
                            _users.length,
                            (index) => () => _showUserDialog(_users[index]),
                          ),
                          onDelete: List.generate(
                            _users.length,
                            (index) => () => _deleteUser(index),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog pour ajouter/modifier un utilisateur
class UserDialog extends StatefulWidget {
  final User? user;
  final Function(User) onSave;

  const UserDialog({
    Key? key,
    this.user,
    required this.onSave,
  }) : super(key: key);

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _roleController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _passwordController = TextEditingController(text: widget.user?.password ?? '');
    _fullNameController = TextEditingController(text: widget.user?.fullName ?? '');
    _roleController = TextEditingController(text: widget.user?.role ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final user = User(
        id: widget.user?.id,
        username: _usernameController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text.isEmpty ? null : _fullNameController.text,
        role: _roleController.text.isEmpty ? null : _roleController.text,
        createdAt: widget.user?.createdAt,
      );
      widget.onSave(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Nouvel utilisateur' : 'Modifier l\'utilisateur'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nom d\'utilisateur *'),
                validator: (value) => value?.isEmpty == true ? 'Nom d\'utilisateur requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe *'),
                obscureText: true,
                validator: (value) => value?.isEmpty == true ? 'Mot de passe requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Rôle'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}