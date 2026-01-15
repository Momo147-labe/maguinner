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
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await DatabaseHelper.instance.getCustomers();
      final rows = await _buildCustomerRows(customers);
      setState(() {
        _customers = customers;
        _tableRows = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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

  Future<List<List<String>>> _buildCustomerRows(
    List<Customer> customers,
  ) async {
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

  void _showCustomerDialog({Customer? customer}) {
    showDialog(
      context: context,
      builder: (context) => ClientDialog(
        customer: customer,
        onSave: (savedCustomer) async {
          try {
            if (customer != null) {
              await DatabaseHelper.instance.updateCustomer(savedCustomer);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Client modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              await DatabaseHelper.instance.insertCustomer(savedCustomer);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Client créé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (!mounted) return;
            Navigator.pop(context);
            _loadCustomers();
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

  Future<void> _exportCustomers(String format) async {
    try {
      if (format == 'pdf') {
        await ExportService.exportCustomersPDF(_customers);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (format == 'excel') {
        await ExportService.exportCustomersExcel(_customers);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export Excel généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export: $e')));
    }
  }

  void _viewCustomerDetails(int index) {
    final customer = _customers[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
  }

  void _editCustomer(int index) {
    _showCustomerDialog(customer: _customers[index]);
  }

  Future<void> _deleteCustomer(int index) async {
    final customer = _customers[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le client "${customer.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteCustomer(customer.id!);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadCustomers();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Client supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCustomerDialog(),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Nouveau Client', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                  onSelected: (value) => _exportCustomers(value),
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
                      color: Colors.blue,
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
              'Date création',
            ],
            rows: _tableRows,
            onDetails: List.generate(
              _customers.length,
              (index) =>
                  () => _viewCustomerDetails(index),
            ),
            onEdit: List.generate(
              _customers.length,
              (index) =>
                  () => _editCustomer(index),
            ),
            onDelete: List.generate(
              _customers.length,
              (index) =>
                  () => _deleteCustomer(index),
            ),
          ),
        ),
      ],
    );
  }
}

class ClientDialog extends StatefulWidget {
  final Customer? customer;
  final Function(Customer) onSave;

  const ClientDialog({Key? key, this.customer, required this.onSave})
    : super(key: key);

  @override
  State<ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<ClientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
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
        const SnackBar(content: Text('Le nom du client est obligatoire')),
      );
      return;
    }

    final customer = Customer(
      id: widget.customer?.id,
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
      createdAt: widget.customer?.createdAt ?? DateTime.now().toIso8601String(),
    );

    widget.onSave(customer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.customer != null;

    return Dialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                        isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Modifier le Client' : 'Nouveau Client',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du client *',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: Text(isEditing ? 'Modifier' : 'Créer'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
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
      ),
    );
  }
}
