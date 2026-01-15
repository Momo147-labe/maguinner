import 'package:flutter/material.dart';
import '../widgets/advanced_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/supplier.dart';
import '../screens/supplier_details_screen.dart';
import '../services/export_service.dart';

/// Page de gestion des fournisseurs avec interface professionnelle Desktop
class SuppliersContent extends StatefulWidget {
  final User currentUser;

  const SuppliersContent({Key? key, required this.currentUser})
    : super(key: key);

  @override
  State<SuppliersContent> createState() => _SuppliersContentState();
}

class _SuppliersContentState extends State<SuppliersContent> {
  List<Supplier> _suppliers = [];
  List<List<String>> _tableRows = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final suppliers = await DatabaseHelper.instance.getSuppliers();
      final rows = await _buildSupplierRows(suppliers);
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _filteredSuppliers = suppliers;
          _tableRows = rows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<double> _calculateSupplierPurchases(int supplierId) async {
    try {
      final purchases = await DatabaseHelper.instance.getPurchases();
      double totalPurchases = 0;

      for (final purchase in purchases) {
        if (purchase.supplierId == supplierId) {
          totalPurchases += purchase.totalAmount ?? 0;
        }
      }

      return totalPurchases;
    } catch (e) {
      return 0;
    }
  }

  Future<List<List<String>>> _buildSupplierRows(
    List<Supplier> suppliers,
  ) async {
    final List<List<String>> rows = [];

    for (final supplier in suppliers) {
      final totalPurchases = await _calculateSupplierPurchases(supplier.id!);
      rows.add([
        supplier.name,
        supplier.phone ?? '-',
        supplier.address ?? '-',
        '${totalPurchases.toStringAsFixed(0)} GNF',
        _formatDate(supplier.createdAt),
      ]);
    }

    return rows;
  }

  void _filterSuppliers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredSuppliers = _suppliers;
          _tableRows = _buildFilteredRows(_suppliers);
        });
      }
    } else {
      final filtered = _suppliers
          .where(
            (supplier) =>
                supplier.name.toLowerCase().contains(query) ||
                (supplier.phone?.toLowerCase().contains(query) ?? false) ||
                (supplier.email?.toLowerCase().contains(query) ?? false) ||
                (supplier.address?.toLowerCase().contains(query) ?? false),
          )
          .toList();

      if (mounted) {
        setState(() {
          _filteredSuppliers = filtered;
          _tableRows = _buildFilteredRows(filtered);
        });
      }
    }
  }

  List<List<String>> _buildFilteredRows(List<Supplier> suppliers) {
    final List<List<String>> rows = [];

    for (int i = 0; i < suppliers.length; i++) {
      final supplier = suppliers[i];
      final originalIndex = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (originalIndex >= 0 && originalIndex < _tableRows.length) {
        rows.add(_tableRows[originalIndex]);
      }
    }

    return rows;
  }

  void _showSupplierDialog({Supplier? supplier}) {
    showDialog(
      context: context,
      builder: (context) => SupplierDialog(
        supplier: supplier,
        onSave: (savedSupplier) async {
          try {
            if (supplier != null) {
              await DatabaseHelper.instance.updateSupplier(savedSupplier);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fournisseur modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              await DatabaseHelper.instance.insertSupplier(savedSupplier);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fournisseur créé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (!mounted) return;
            Navigator.pop(context);
            _loadSuppliers();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
            }
          }
        },
      ),
    );
  }

  Future<void> _exportSuppliers(String format) async {
    if (!mounted) return;
    try {
      if (format == 'pdf') {
        await ExportService.exportSuppliersPDF(_suppliers);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export PDF généré avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (format == 'excel') {
        await ExportService.exportSuppliersExcel(_suppliers);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export Excel généré avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export: $e')));
      }
    }
  }

  void _viewSupplierDetails(int index) {
    final supplier = _filteredSuppliers[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierDetailsScreen(supplier: supplier),
      ),
    );
  }

  void _editSupplier(int index) {
    _showSupplierDialog(supplier: _filteredSuppliers[index]);
  }

  Future<void> _deleteSupplier(int index) async {
    final supplier = _filteredSuppliers[index];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le fournisseur "${supplier.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              try {
                if (supplier.id != null) {
                  await DatabaseHelper.instance.deleteSupplier(supplier.id!);
                  navigator.pop();
                  _loadSuppliers();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Fournisseur supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (navigator.canPop()) {
                  navigator.pop();
                }
                messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // En-tête avec bouton Nouveau Fournisseur
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;
            if (isNarrow) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showSupplierDialog(),
                            icon: const Icon(Icons.business_center),
                            label: const Text('Nouveau'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) => _exportSuppliers(value),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'pdf',
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('PDF'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'excel',
                              child: Row(
                                children: [
                                  Icon(Icons.table_chart, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Excel'),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un fournisseur...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) => _filterSuppliers(),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSupplierDialog(),
                      icon: const Icon(Icons.business_center, size: 18),
                      label: const Text('Nouveau Fournisseur', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: PopupMenuButton<String>(
                      onSelected: (value) => _exportSuppliers(value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Exporter PDF', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Exporter Excel', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Exporter', style: TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Tableau des fournisseurs
        Expanded(
          child: AdvancedDataTable(
            title: 'Gestion des Fournisseurs',
            columns: const [
              'Nom',
              'Téléphone',
              'Adresse',
              'Total achats (GNF)',
              'Date création',
            ],
            rows: _tableRows,
            onDetails: List.generate(
              _filteredSuppliers.length,
              (index) =>
                  () => _viewSupplierDetails(index),
            ),
            onEdit: List.generate(
              _filteredSuppliers.length,
              (index) =>
                  () => _editSupplier(index),
            ),
            onDelete: List.generate(
              _filteredSuppliers.length,
              (index) =>
                  () => _deleteSupplier(index),
            ),
          ),
        ),
      ],
    );
  }
}

class SupplierDialog extends StatefulWidget {
  final Supplier? supplier;
  final Function(Supplier) onSave;

  const SupplierDialog({Key? key, this.supplier, required this.onSave})
    : super(key: key);

  @override
  State<SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<SupplierDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.supplier?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.supplier?.email ?? '',
    );
    _addressController = TextEditingController(
      text: widget.supplier?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du fournisseur est obligatoire')),
      );
      return;
    }

    final supplier = Supplier(
      id: widget.supplier?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      createdAt: widget.supplier?.createdAt ?? DateTime.now().toIso8601String(),
    );

    widget.onSave(supplier);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.supplier != null;

    return Dialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.domain_add_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing ? 'Modifier le Fournisseur' : 'Nouveau Fournisseur',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom du fournisseur *',
                prefixIcon: const Icon(Icons.business_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Adresse',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                  onPressed: _submit,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(isEditing ? 'Modifier' : 'Créer'),
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
    );
  }
}
