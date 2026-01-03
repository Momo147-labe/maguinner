import 'package:flutter/material.dart';
import '../widgets/advanced_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/customer.dart';
import '../screens/customer_details_screen.dart';
import '../services/export_service.dart';

/// Page de gestion des clients avec interface professionnelle Desktop
class ClientsContent extends StatefulWidget {
  final User currentUser;

  const ClientsContent({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ClientsContent> createState() => _ClientsContentState();
}

class _ClientsContentState extends State<ClientsContent> {
  List<Customer> _customers = [];
  List<List<String>> _tableRows = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
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

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await DatabaseHelper.instance.getCustomers();
      final rows = await _buildCustomerRows(customers);
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _tableRows = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<double> _calculateCustomerDebt(int customerId) async {
    try {
      final sales = await DatabaseHelper.instance.getSales();
      double totalDebt = 0;
      
      for (final sale in sales) {
        if (sale.customerId == customerId) {
          totalDebt += sale.totalAmount ?? 0;
        }
      }
      
      return totalDebt;
    } catch (e) {
      return 0;
    }
  }

  Future<List<List<String>>> _buildCustomerRows(List<Customer> customers) async {
    final List<List<String>> rows = [];
    
    for (final customer in customers) {
      final debt = await _calculateCustomerDebt(customer.id!);
      rows.add([
        customer.name,
        customer.phone ?? '-',
        customer.address ?? '-',
        '${debt.toStringAsFixed(0)} GNF',
        _formatDate(customer.createdAt),
      ]);
    }
    
    return rows;
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredCustomers = _customers;
        _tableRows = _buildFilteredRows(_customers);
      });
    } else {
      final filtered = _customers.where((customer) =>
        customer.name.toLowerCase().contains(query) ||
        (customer.phone?.toLowerCase().contains(query) ?? false) ||
        (customer.email?.toLowerCase().contains(query) ?? false) ||
        (customer.address?.toLowerCase().contains(query) ?? false)
      ).toList();
      
      setState(() {
        _filteredCustomers = filtered;
        _tableRows = _buildFilteredRows(filtered);
      });
    }
  }

  List<List<String>> _buildFilteredRows(List<Customer> customers) {
    final List<List<String>> rows = [];
    
    for (int i = 0; i < customers.length; i++) {
      final customer = customers[i];
      final originalIndex = _customers.indexWhere((c) => c.id == customer.id);
      if (originalIndex >= 0 && originalIndex < _tableRows.length) {
        rows.add(_tableRows[originalIndex]);
      }
    }
    
    return rows;
  }

  void _showCustomerDialog({Customer? customer}) {
    final isEditing = customer != null;
    
    if (isEditing) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _addressController.text = customer.address ?? '';
    } else {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _addressController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier le Client' : 'Nouveau Client'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du client *',
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
            onPressed: () => _saveCustomer(customer),
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

  Future<void> _saveCustomer(Customer? existingCustomer) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du client est obligatoire')),
      );
      return;
    }

    try {
      final customer = Customer(
        id: existingCustomer?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        createdAt: existingCustomer?.createdAt ?? DateTime.now().toIso8601String(),
      );

      if (existingCustomer != null) {
        await DatabaseHelper.instance.updateCustomer(customer);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await DatabaseHelper.instance.insertCustomer(customer);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
      _loadCustomers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _exportCustomers(String format) async {
    try {
      if (format == 'pdf') {
        await ExportService.exportCustomersPDF(_customers);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (format == 'excel') {
        await ExportService.exportCustomersExcel(_customers);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export Excel généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'export: $e')),
      );
    }
  }

  void _viewCustomerDetails(int index) {
    final customer = _filteredCustomers[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
  }

  void _editCustomer(int index) {
    _showCustomerDialog(customer: _filteredCustomers[index]);
  }

  Future<void> _deleteCustomer(int index) async {
    final customer = _filteredCustomers[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le client "${customer.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteCustomer(customer.id!);
                Navigator.pop(context);
                _loadCustomers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Client supprimé avec succès'),
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
        // En-tête avec bouton Nouveau Client
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCustomerDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Nouveau Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                onSelected: (value) => _exportCustomers(value),
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
                    color: Colors.blue,
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
                    hintText: 'Rechercher un client...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => _filterCustomers(),
                ),
              ),
            ],
          ),
        ),
        
        // Tableau des clients
        Expanded(
          child: AdvancedDataTable(
            title: 'Gestion des Clients',
            columns: const [
              'Nom',
              'Téléphone',
              'Adresse',
              'Solde (GNF)',
              'Date création'
            ],
            rows: _tableRows,
            onDetails: List.generate(
              _filteredCustomers.length,
              (index) => () => _viewCustomerDetails(index),
            ),
            onEdit: List.generate(
              _filteredCustomers.length,
              (index) => () => _editCustomer(index),
            ),
            onDelete: List.generate(
              _filteredCustomers.length,
              (index) => () => _deleteCustomer(index),
            ),
          ),
        ),
      ],
    );
  }
}