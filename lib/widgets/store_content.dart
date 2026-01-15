import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/store_info.dart';
import '../core/database/database_helper.dart';
import '../services/theme_service.dart';
import '../screens/badges_screen.dart';
import '../screens/user_guide_screen.dart';
import '../models/user.dart';
import 'dart:io';

class StoreContent extends StatefulWidget {
  final User? currentUser;

  const StoreContent({Key? key, this.currentUser}) : super(key: key);

  @override
  State<StoreContent> createState() => _StoreContentState();
}

class _StoreContentState extends State<StoreContent> {
  StoreInfo? _storeInfo;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;
  Color _currentPrimaryColor = Colors.blue;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
    _loadCurrentColor();
  }

  Future<void> _loadCurrentColor() async {
    final color = await ThemeService.getPrimaryColor();
    setState(() => _currentPrimaryColor = color);
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
                            color: _currentPrimaryColor == color
                                ? Colors.black
                                : Colors.grey,
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
          content: Text(
            'Couleur changée en ${ThemeService.getColorName(selectedColor!)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Redémarrer l'application pour appliquer la nouvelle couleur
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/restart', (route) => false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreInfo() async {
    setState(() => _isLoading = true);
    try {
      final storeInfo = await DatabaseHelper.instance.getStoreInfo();
      if (mounted) {
        setState(() {
          _storeInfo = storeInfo;
          if (storeInfo != null) {
            _nameController.text = storeInfo.name;
            _ownerController.text = storeInfo.ownerName;
            _phoneController.text = storeInfo.phone;
            _emailController.text = storeInfo.email;
            _locationController.text = storeInfo.location;
          }
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

  Future<void> _saveStoreInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updatedStore = StoreInfo(
        id: 1, // Toujours utiliser id = 1
        name: _nameController.text.trim(),
        ownerName: _ownerController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        location: _locationController.text.trim(),
        createdAt: _storeInfo?.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.updateStoreInfo(updatedStore);

      if (mounted) {
        setState(() {
          _storeInfo = updatedStore;
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations du magasin mises à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de la sauvegarde: $e';
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _error = null;
      if (_storeInfo != null) {
        _nameController.text = _storeInfo!.name;
        _ownerController.text = _storeInfo!.ownerName;
        _phoneController.text = _storeInfo!.phone;
        _emailController.text = _storeInfo!.email;
        _locationController.text = _storeInfo!.location;
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_storeInfo == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_mall_directory,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune information de magasin trouvée',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez contacter l\'administrateur',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          // Header responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.store_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mon Magasin',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Gérez les informations de votre établissement',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Modifier'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (widget.currentUser != null)
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BadgesScreen(
                                      currentUser: widget.currentUser!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.badge_rounded),
                              label: const Text('Badges'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          FilledButton.icon(
                            onPressed: _changeAppColor,
                            icon: const Icon(Icons.palette_rounded),
                            label: const Text('Couleur'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _currentPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserGuideScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.help_outline_rounded),
                            label: const Text('Guide'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              } else {
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mon Magasin',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Gérez les informations de votre établissement',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isEditing) ...[
                      FilledButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Modifier'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.currentUser != null)
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BadgesScreen(
                                  currentUser: widget.currentUser!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.badge_rounded),
                          label: const Text('Badges'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _changeAppColor,
                        icon: const Icon(Icons.palette_rounded),
                        label: const Text('Couleur'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _currentPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserGuideScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.help_outline_rounded),
                        label: const Text('Guide'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),

          // Error message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Store information card
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Informations du Magasin',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _nameController,
                            label: 'Nom du magasin',
                            icon: Icons.store_rounded,
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Nom du magasin obligatoire';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: _ownerController,
                            label: 'Propriétaire',
                            icon: Icons.person_rounded,
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Nom du propriétaire obligatoire';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _phoneController,
                            label: 'Téléphone',
                            icon: Icons.phone_rounded,
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Téléphone obligatoire';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_rounded,
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Email obligatoire';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value!.trim())) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: _locationController,
                      label: 'Localisation',
                      icon: Icons.location_on_rounded,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Localisation obligatoire';
                        }
                        return null;
                      },
                    ),

                    if (_isEditing) ...[
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving ? null : _cancelEdit,
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
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _saveStoreInfo,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _isSaving ? 'Sauvegarde...' : 'Sauvegarder',
                            ),
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
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Store statistics card
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Informations Système',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          'Date de création',
                          _formatDate(_storeInfo!.createdAt),
                          Icons.calendar_today_rounded,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoTile(
                          'Dernière modification',
                          _formatDate(_storeInfo!.updatedAt),
                          Icons.update_rounded,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Developer information card (read-only)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.code_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Informations du Développeur',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.purple.shade900.withValues(alpha: 0.3)
                          : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.purple.shade700
                            : Colors.purple.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDeveloperInfoRow(
                          'Nom complet',
                          'Fodé Momo Soumah',
                          Icons.person,
                        ),
                        const SizedBox(height: 12),
                        _buildDeveloperInfoRow(
                          'Téléphone',
                          '627172530 / 666761076',
                          Icons.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildDeveloperInfoRow(
                          'Email',
                          'fodemomos11@gmail.com',
                          Icons.email,
                        ),
                        const SizedBox(height: 12),
                        _buildDeveloperInfoRow(
                          'Adresse',
                          'Hafia (Labé)',
                          Icons.location_on,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _isEditing
            ? (isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface)
            : (isDark
                  ? theme.colorScheme.surfaceContainer
                  : theme.colorScheme.surfaceContainerLow),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
      ),
      enabled: _isEditing,
      validator: validator,
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? color.shade200 : color.shade700;
    final containerColor = isDark
        ? color.shade900.withOpacity(0.3)
        : color.shade50;
    final iconContainerColor = isDark
        ? color.shade800.withOpacity(0.5)
        : color.shade100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? color.shade800 : color.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconContainerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Non défini';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date invalide';
    }
  }
}
