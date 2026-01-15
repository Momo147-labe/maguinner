import 'package:flutter/material.dart';
import '../models/user.dart';

/// Widget pour la gestion de l'inventaire
class InventoryContent extends StatefulWidget {
  final User currentUser;

  const InventoryContent({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Gestion de l\'Inventaire - En développement',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

/// Widget pour les rapports
class ReportsContent extends StatefulWidget {
  final User currentUser;

  const ReportsContent({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Rapports - En développement',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

/// Widget pour la gestion des utilisateurs
class UsersContent extends StatefulWidget {
  final User currentUser;

  const UsersContent({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<UsersContent> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Gestion des Utilisateurs - En développement',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}