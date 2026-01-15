import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/user.dart';
import '../core/database/database_helper.dart';
import '../services/invoice_service.dart';
import '../utils/responsive_helper.dart';

class InvoicesScreen extends StatefulWidget {
  final User currentUser;

  const InvoicesScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Sale> _sales = [];
  List<Purchase> _purchases = [];
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sales = await DatabaseHelper.instance.getSales();
      final purchases = await DatabaseHelper.instance.getPurchases();
      final customers = await DatabaseHelper.instance.getCustomers();
      final suppliers = await DatabaseHelper.instance.getSuppliers();
      
      setState(() {
        _sales = sales;
        _purchases = purchases;
        _customers = customers;
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  List<Sale> get _filteredSales {
    if (_searchQuery.isEmpty) return _sales;
    return _sales.where((sale) {
      final customer = _customers.firstWhere(
        (c) => c.id == sale.customerId,
        orElse: () => Customer(name: 'Vente directe'),
      );
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             sale.id.toString().contains(_searchQuery);
    }).toList();
  }

  List<Purchase> get _filteredPurchases {
    if (_searchQuery.isEmpty) return _purchases;
    return _purchases.where((purchase) {
      final supplier = _suppliers.firstWhere(
        (s) => s.id == purchase.supplierId,
        orElse: () => Supplier(name: 'Achat direct'),
      );
      return supplier.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             purchase.id.toString().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt_long),
              text: 'Ventes (${_sales.length})',
            ),
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: 'Achats (${_purchases.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher par client/fournisseur ou N° facture...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(isMobile),
                _buildPurchasesTab(isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab(bool isMobile) {
    if (_filteredSales.isEmpty) {
      return const Center(
        child: Text('Aucune facture de vente trouvée'),
      );
    }

    return isMobile ? _buildSalesList() : _buildSalesTable();
  }

  Widget _buildPurchasesTab(bool isMobile) {
    if (_filteredPurchases.isEmpty) {
      return const Center(
        child: Text('Aucun bon d\'achat trouvé'),
      );
    }

    return isMobile ? _buildPurchasesList() : _buildPurchasesTable();
  }

  Widget _buildSalesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredSales.length,
      itemBuilder: (context, index) {
        final sale = _filteredSales[index];
        final customer = _customers.firstWhere(
          (c) => c.id == sale.customerId,
          orElse: () => Customer(name: 'Vente directe'),
        );
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPaymentTypeColor(sale.paymentType),
              child: Text('${sale.id}'),
            ),
            title: Text(customer.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${_formatDate(sale.saleDate)}'),
                Text('Type: ${_getPaymentTypeLabel(sale.paymentType)}'),
                if (sale.dueDate != null)
                  Text('Échéance: ${_formatDate(sale.dueDate)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _generateSaleInvoice(sale),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPurchasesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredPurchases.length,
      itemBuilder: (context, index) {
        final purchase = _filteredPurchases[index];
        final supplier = _suppliers.firstWhere(
          (s) => s.id == purchase.supplierId,
          orElse: () => Supplier(name: 'Achat direct'),
        );
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPaymentTypeColor(purchase.paymentType),
              child: Text('${purchase.id}'),
            ),
            title: Text(supplier.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${_formatDate(purchase.purchaseDate)}'),
                Text('Type: ${_getPaymentTypeLabel(purchase.paymentType)}'),
                if (purchase.dueDate != null)
                  Text('Échéance: ${_formatDate(purchase.dueDate)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(purchase.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _generatePurchaseInvoice(purchase),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('N°')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Client')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Montant')),
          DataColumn(label: Text('Échéance')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _filteredSales.map((sale) {
          final customer = _customers.firstWhere(
            (c) => c.id == sale.customerId,
            orElse: () => Customer(name: 'Vente directe'),
          );
          
          return DataRow(
            cells: [
              DataCell(Text('${sale.id}')),
              DataCell(Text(_formatDate(sale.saleDate))),
              DataCell(Text(customer.name)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPaymentTypeColor(sale.paymentType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPaymentTypeLabel(sale.paymentType),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              DataCell(Text(sale.dueDate != null ? _formatDate(sale.dueDate) : '-')),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _generateSaleInvoice(sale),
                  tooltip: 'Générer PDF',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPurchasesTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('N°')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Fournisseur')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Montant')),
          DataColumn(label: Text('Échéance')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _filteredPurchases.map((purchase) {
          final supplier = _suppliers.firstWhere(
            (s) => s.id == purchase.supplierId,
            orElse: () => Supplier(name: 'Achat direct'),
          );
          
          return DataRow(
            cells: [
              DataCell(Text('${purchase.id}')),
              DataCell(Text(_formatDate(purchase.purchaseDate))),
              DataCell(Text(supplier.name)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPaymentTypeColor(purchase.paymentType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPaymentTypeLabel(purchase.paymentType),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${(purchase.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              DataCell(Text(purchase.dueDate != null ? _formatDate(purchase.dueDate) : '-')),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _generatePurchaseInvoice(purchase),
                  tooltip: 'Générer PDF',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _generateSaleInvoice(Sale sale) async {
    try {
      await InvoiceService.generateSaleInvoice(sale);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facture générée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _generatePurchaseInvoice(Purchase purchase) async {
    try {
      await InvoiceService.generatePurchaseInvoice(purchase);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bon d\'achat généré avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
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

  String _getPaymentTypeLabel(String? paymentType) {
    switch (paymentType) {
      case 'direct':
        return 'Direct';
      case 'client':
        return 'Client';
      case 'credit':
        return 'Crédit';
      case 'debt':
        return 'Dette';
      default:
        return 'Direct';
    }
  }

  Color _getPaymentTypeColor(String? paymentType) {
    switch (paymentType) {
      case 'direct':
        return Colors.green;
      case 'client':
        return Colors.blue;
      case 'credit':
        return Colors.orange;
      case 'debt':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}