import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/user.dart';
import '../models/store_info.dart';
import '../core/database/database_helper.dart';
import '../services/badge_service.dart';
import '../services/theme_service.dart';

class BadgesScreen extends StatefulWidget {
  final User currentUser;

  const BadgesScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  StoreInfo? _storeInfo;
  List<User> _users = [];
  User? _selectedUser;
  int _selectedTemplate = 1;
  Uint8List? _userPhoto;
  bool _isLoading = true;
  Color _currentPrimaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCurrentColor();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final store = await DatabaseHelper.instance.getStoreInfo();
      final users = await DatabaseHelper.instance.getUsers();
      
      setState(() {
        _storeInfo = store;
        _users = users;
        // Vérifier que l'utilisateur actuel existe dans la liste
        if (users.any((u) => u.id == widget.currentUser.id)) {
          _selectedUser = users.firstWhere((u) => u.id == widget.currentUser.id);
        } else if (users.isNotEmpty) {
          _selectedUser = users.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _loadCurrentColor() async {
    final color = await ThemeService.getPrimaryColor();
    setState(() => _currentPrimaryColor = color);
  }

  Future<void> _pickImage() async {
    // Désactiver la sélection d'image sur Linux Desktop pour éviter les erreurs de canal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélection d\'image non disponible sur cette plateforme. Badge généré sans photo.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _generateBadge() async {
    if (_selectedUser == null || _storeInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données manquantes pour générer le badge')),
      );
      return;
    }

    try {
      await BadgeService.generateBadgePDF(
        _selectedUser!,
        _storeInfo!,
        _selectedTemplate,
        userPhoto: _userPhoto,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Badge généré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération: $e')),
      );
    }
  }

  Future<void> _changeAppColor() async {
    Color? selectedColor;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la couleur principale'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Couleurs prédéfinies:'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ThemeService.availableColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        selectedColor = color;
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _currentPrimaryColor == color ? Colors.black : Colors.grey,
                            width: _currentPrimaryColor == color ? 3 : 1,
                          ),
                        ),
                        child: _currentPrimaryColor == color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Couleur personnalisée:'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sélecteur de couleur'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: _currentPrimaryColor,
                            onColorChanged: (color) => selectedColor = color,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Valider'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Sélecteur avancé'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedColor != null) {
      await ThemeService.savePrimaryColor(selectedColor!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Couleur changée en ${ThemeService.getColorName(selectedColor!)}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Redémarrer l'application pour appliquer la nouvelle couleur
      Navigator.of(context).pushNamedAndRemoveUntil('/restart', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges Utilisateurs'),
        backgroundColor: _currentPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _changeAppColor,
            icon: const Icon(Icons.palette),
            tooltip: 'Changer la couleur',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Panneau de configuration
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration du Badge',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Sélection utilisateur
                      const Text('Utilisateur:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedUser?.id,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _users.map((user) {
                          return DropdownMenuItem<int>(
                            value: user.id,
                            child: Text(user.fullName ?? user.username ?? ''),
                          );
                        }).toList(),
                        onChanged: (userId) {
                          if (userId != null) {
                            final user = _users.firstWhere((u) => u.id == userId);
                            setState(() {
                              _selectedUser = user;
                              _userPhoto = null; // Reset photo
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Photo utilisateur
                      const Text('Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _userPhoto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.memory(_userPhoto!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Choisir photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Modèle de badge
                      const Text('Modèle de badge:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2,
                          ),
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            final templateId = index + 1;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTemplate = templateId),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedTemplate == templateId 
                                        ? _currentPrimaryColor 
                                        : Colors.grey,
                                    width: _selectedTemplate == templateId ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Modèle $templateId',
                                    style: TextStyle(
                                      fontWeight: _selectedTemplate == templateId 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      color: _selectedTemplate == templateId 
                                          ? _currentPrimaryColor 
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Boutons d'action
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generateBadge,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Générer Badge PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Aperçu du badge
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aperçu du Badge',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Center(
                        child: Container(
                          width: 300,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildBadgePreview(),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      if (_selectedUser != null && _storeInfo != null) ...[
                        const Text('Informations du badge:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildInfoRow('Nom', _selectedUser!.fullName ?? _selectedUser!.username ?? ''),
                        _buildInfoRow('Rôle', _getRoleDisplayName(_selectedUser!.role ?? '')),
                        _buildInfoRow('Magasin', _storeInfo!.name),
                        _buildInfoRow('Téléphone', _storeInfo!.phone),
                        _buildInfoRow('Modèle', 'Template $_selectedTemplate'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgePreview() {
    if (_selectedUser == null || _storeInfo == null) {
      return const Center(
        child: Text('Sélectionnez un utilisateur pour voir l\'aperçu'),
      );
    }

    // Aperçu simplifié du badge
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getTemplateColors(_selectedTemplate),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: _userPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.memory(_userPhoto!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.person, size: 35, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedUser!.fullName ?? _selectedUser!.username ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getRoleDisplayName(_selectedUser!.role ?? ''),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _storeInfo!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _storeInfo!.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Color> _getTemplateColors(int templateId) {
    switch (templateId) {
      case 1: return [Colors.blue.shade800, Colors.blue.shade600];
      case 2: return [Colors.green.shade600, Colors.green.shade400];
      case 3: return [Colors.grey.shade900, Colors.grey.shade700];
      case 4: return [Colors.orange.shade600, Colors.deepOrange.shade800];
      case 5: return [Colors.white, Colors.grey.shade100];
      case 6: return [Colors.purple.shade600, Colors.pink.shade600];
      case 7: return [Colors.teal.shade600, Colors.teal.shade400];
      case 8: return [Colors.indigo.shade800, Colors.blue.shade800];
      case 9: return [Colors.red.shade600, Colors.red.shade400];
      case 10: return [Colors.brown.shade600, Colors.orange.shade800];
      default: return [Colors.blue.shade800, Colors.blue.shade600];
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return 'Administrateur';
      case 'gestionnaire': return 'Gestionnaire';
      case 'caissier': return 'Caissier';
      case 'vendeur': return 'Vendeur';
      default: return role;
    }
  }
}