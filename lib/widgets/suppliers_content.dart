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

  const SuppliersContent({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<SuppliersContent> createState() => _SuppliersContentState();
}

class _SuppliersContentState extends State<SuppliersContent> {
  List<Supplier> _suppliers = [];
  List<List<String>> _tableRows = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
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

  Future<List<List<String>>> _buildSupplierRows(List<Supplier> suppliers) async {
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
      final filtered = _suppliers.where((supplier) =>
        supplier.name.toLowerCase().contains(query) ||
        (supplier.phone?.toLowerCase().contains(query) ?? false) ||
        (supplier.email?.toLowerCase().contains(query) ?? false) ||
        (supplier.address?.toLowerCase().contains(query) ?? false)
      ).toList();
      
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
    final isEditing = supplier != null;
    
    if (isEditing) {
      _nameController.text = supplier.name;
      _phoneController.text = supplier.phone ?? '';
      _emailController.text = supplier.email ?? '';
      _addressController.text = supplier.address ?? '';
    } else {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _addressController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier le Fournisseur' : 'Nouveau Fournisseur'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du fournisseur *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _saveSupplier(supplier),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Modifier' : 'Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSupplier(Supplier? existingSupplier) async {
    if (!mounted) return;
    
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du fournisseur est obligatoire')),
      );
      return;
    }

    try {
      final supplier = Supplier(
        id: existingSupplier?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        createdAt: existingSupplier?.createdAt ?? DateTime.now().toIso8601String(),
      );

      if (existingSupplier != null) {
        await DatabaseHelper.instance.updateSupplier(supplier);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fournisseur modifié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await DatabaseHelper.instance.insertSupplier(supplier);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fournisseur créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _loadSuppliers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export: $e')),
        );
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
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le fournisseur "${supplier.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteSupplier(supplier.id!);
                Navigator.pop(context);
                _loadSuppliers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fournisseur supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
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
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showSupplierDialog(),
                icon: const Icon(Icons.business_center),
                label: const Text('Nouveau Fournisseur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                onSelected: (value) => _exportSuppliers(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Exporter PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Exporter Excel'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Exporter', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un fournisseur...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => _filterSuppliers(),
                ),
              ),
            ],
          ),
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
              'Date création'
            ],
            rows: _tableRows,
            onDetails: List.generate(
              _filteredSuppliers.length,
              (index) => () => _viewSupplierDetails(index),
            ),
            onEdit: List.generate(
              _filteredSuppliers.length,
              (index) => () => _editSupplier(index),
            ),
            onDelete: List.generate(
              _filteredSuppliers.length,
              (index) => () => _deleteSupplier(index),
            ),
          ),
        ),
      ],
    );
  }
}