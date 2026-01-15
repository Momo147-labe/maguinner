import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/custom_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/sale.dart';

/// Écran de gestion des ventes
class SalesScreen extends StatefulWidget {
  final User currentUser;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const SalesScreen({
    Key? key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await DatabaseHelper.instance.getSales();
      setState(() {
        _sales = sales;
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

  void _showSaleDialog([Sale? sale]) {
    showDialog(
      context: context,
      builder: (context) => SaleDialog(
        sale: sale,
        onSave: (savedSale) async {
          try {
            if (sale == null) {
              await DatabaseHelper.instance.insertSale(savedSale);
            } else {
              await DatabaseHelper.instance.updateSale(savedSale);
            }
            _loadSales();
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

  Future<void> _deleteSale(int index) async {
    try {
      await DatabaseHelper.instance.deleteSale(_sales[index].id!);
      _loadSales();
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
            currentRoute: '/sales',
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
                          title: 'Gestion des Ventes',
                          columns: const [
                            'ID',
                            'Client ID',
                            'Date de vente',
                            'Montant total',
                          ],
                          rows: _sales.map((sale) => [
                            sale.id.toString(),
                            sale.customerId?.toString() ?? 'N/A',
                            sale.saleDate ?? '',
                            '${sale.totalAmount?.toStringAsFixed(2) ?? '0'} €',
                          ]).toList(),
                          onAdd: () => _showSaleDialog(),
                          onEdit: List.generate(
                            _sales.length,
                            (index) => () => _showSaleDialog(_sales[index]),
                          ),
                          onDelete: List.generate(
                            _sales.length,
                            (index) => () => _deleteSale(index),
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

/// Dialog pour ajouter/modifier une vente
class SaleDialog extends StatefulWidget {
  final Sale? sale;
  final Function(Sale) onSave;

  const SaleDialog({
    Key? key,
    this.sale,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerIdController;
  late final TextEditingController _totalAmountController;

  @override
  void initState() {
    super.initState();
    _customerIdController = TextEditingController(
      text: widget.sale?.customerId?.toString() ?? '',
    );
    _totalAmountController = TextEditingController(
      text: widget.sale?.totalAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final sale = Sale(
        id: widget.sale?.id,
        customerId: int.tryParse(_customerIdController.text),
        saleDate: DateTime.now().toIso8601String(),
        totalAmount: double.tryParse(_totalAmountController.text),
      );
      widget.onSave(sale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.sale == null ? 'Nouvelle vente' : 'Modifier la vente'),
      content: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _customerIdController,
                decoration: const InputDecoration(labelText: 'ID Client'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalAmountController,
                decoration: const InputDecoration(labelText: 'Montant total'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Montant requis';
                  if (double.tryParse(value!) == null) return 'Montant invalide';
                  return null;
                },
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