import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/sale_line.dart';
import '../models/purchase_line.dart';
import '../core/database/database_helper.dart';

class ReportsContent extends StatefulWidget {
  final User currentUser;

  const ReportsContent({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  List<Sale> _sales = [];
  List<Purchase> _purchases = [];
  List<User> _users = [];
  Map<int, String> _customerNames = {};
  Map<int, String> _supplierNames = {};
  Map<int, String> _productNames = {};
  Map<int, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    try {
      final sales = await DatabaseHelper.instance.getSales();
      final purchases = await DatabaseHelper.instance.getPurchases();
      final users = await DatabaseHelper.instance.getUsers();
      final customers = await DatabaseHelper.instance.getCustomers();
      final suppliers = await DatabaseHelper.instance.getSuppliers();
      final products = await DatabaseHelper.instance.getProducts();

      if (mounted) {
        setState(() {
          _sales = sales;
          _purchases = purchases;
          _users = users;
          _customerNames = {for (var c in customers) c.id!: c.name!};
          _supplierNames = {for (var s in suppliers) s.id!: s.name!};
          _productNames = {for (var p in products) p.id!: p.name!};
          _userNames = {for (var u in users) u.id!: u.fullName ?? u.username!};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<double> _calculateTotalProfit() async {
    double totalProfit = 0;
    for (final sale in _sales) {
      if (sale.id != null) {
        final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
        for (final line in saleLines) {
          final product = await DatabaseHelper.instance.getProduct(line.productId!);
          if (product != null) {
            final profit = (line.salePrice! - (product.purchasePrice ?? 0)) * line.quantity!;
            totalProfit += profit;
          }
        }
      }
    }
    return totalProfit;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSalesReport(),
              _buildPurchasesReport(),
              _buildUsersReport(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, color: Colors.blue.shade700, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rapports & Analyses',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rapports détaillés des ventes, achats et utilisateurs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadReportsData,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            labelColor: isDark ? Colors.white : Colors.black87,
            unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            indicatorColor: Colors.blue.shade600,
            tabs: const [
              Tab(icon: Icon(Icons.point_of_sale), text: 'Ventes'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Achats'),
              Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesReport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double totalSales = _sales.fold(0, (sum, sale) => sum + (sale.totalAmount ?? 0));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  'Total Vendu',
                  '${totalSales.toStringAsFixed(0)} GNF',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<double>(
                  future: _calculateTotalProfit(),
                  builder: (context, snapshot) {
                    final profit = snapshot.data ?? 0;
                    return _buildReportCard(
                      'Bénéfices Totaux',
                      '${profit.toStringAsFixed(0)} GNF',
                      Icons.trending_up,
                      Colors.blue,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReportCard(
                  'Nombre de Ventes',
                  '${_sales.length}',
                  Icons.receipt,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _exportSalesReport('pdf'),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _exportSalesReport('excel'),
                icon: const Icon(Icons.table_chart),
                label: const Text('Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détail des Ventes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Client')),
                        DataColumn(label: Text('Utilisateur')),
                        DataColumn(label: Text('Montant')),
                        DataColumn(label: Text('Bénéfice')),
                        DataColumn(label: Text('Type Paiement')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _sales.map((sale) => DataRow(
                        cells: [
                          DataCell(Text(sale.saleDate?.substring(0, 10) ?? '')),
                          DataCell(Text(_customerNames[sale.customerId] ?? 'Client direct')),
                          DataCell(Text(_userNames[sale.userId] ?? 'Inconnu')),
                          DataCell(Text('${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF')),
                          DataCell(
                            FutureBuilder<double>(
                              future: _calculateSaleProfit(sale),
                              builder: (context, snapshot) {
                                final profit = snapshot.data ?? 0;
                                return Text(
                                  '${profit.toStringAsFixed(0)} GNF',
                                  style: TextStyle(
                                    color: profit > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          DataCell(Text(sale.paymentType ?? 'direct')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _showSaleDetails(sale),
                            ),
                          ),
                        ],
                      )).toList(),
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

  Future<double> _calculateSaleProfit(Sale sale) async {
    if (sale.id == null) return 0;
    double profit = 0;
    final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
    for (final line in saleLines) {
      final product = await DatabaseHelper.instance.getProduct(line.productId!);
      if (product != null) {
        profit += (line.salePrice! - (product.purchasePrice ?? 0)) * line.quantity!;
      }
    }
    return profit;
  }

  Widget _buildPurchasesReport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double totalPurchases = _purchases.fold(0, (sum, purchase) => sum + (purchase.totalAmount ?? 0));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  'Total Acheté',
                  '${totalPurchases.toStringAsFixed(0)} GNF',
                  Icons.shopping_bag,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReportCard(
                  'Nombre d\'Achats',
                  '${_purchases.length}',
                  Icons.receipt_long,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _exportPurchasesReport('pdf'),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _exportPurchasesReport('excel'),
                icon: const Icon(Icons.table_chart),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détail des Achats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Fournisseur')),
                        DataColumn(label: Text('Utilisateur')),
                        DataColumn(label: Text('Montant')),
                        DataColumn(label: Text('Type Paiement')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _purchases.map((purchase) => DataRow(
                        cells: [
                          DataCell(Text(purchase.purchaseDate?.substring(0, 10) ?? '')),
                          DataCell(Text(_supplierNames[purchase.supplierId] ?? 'Inconnu')),
                          DataCell(Text(_userNames[purchase.userId] ?? 'Inconnu')),
                          DataCell(Text('${(purchase.totalAmount ?? 0).toStringAsFixed(0)} GNF')),
                          DataCell(Text(purchase.paymentType ?? 'direct')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _showPurchaseDetails(purchase),
                            ),
                          ),
                        ],
                      )).toList(),
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

  Widget _buildUsersReport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  'Utilisateurs Actifs',
                  '${_users.length}',
                  Icons.people,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Container()),
              ElevatedButton.icon(
                onPressed: () => _exportUsersReport('pdf'),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _exportUsersReport('excel'),
                icon: const Icon(Icons.table_chart),
                label: const Text('Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._users.map((user) => _buildDetailedUserReportCard(user)),
        ],
      ),
    );
  }

  Widget _buildDetailedUserReportCard(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userSales = _sales.where((sale) => sale.userId == user.id).toList();
    final totalUserSales = userSales.fold(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role ?? 'vendeur'),
                  child: Text(
                    (user.fullName ?? user.username ?? '').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? user.username ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${user.role ?? 'vendeur'} • Créé le ${user.createdAt?.substring(0, 10) ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getRoleColor(user.role ?? 'vendeur'),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${userSales.length} ventes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${totalUserSales.toStringAsFixed(0)} GNF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (userSales.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Activité détaillée:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getUserProductsSold(user.id!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final productsSold = snapshot.data!;
                  return Column(
                    children: [
                      ...userSales.take(5).map((sale) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.point_of_sale, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              sale.saleDate?.substring(0, 16) ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Text(
                              '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                      if (productsSold.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Produits les plus vendus:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        ...productsSold.take(3).map((product) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  product['name'],
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                '${product['quantity']} vendus',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getUserProductsSold(int userId) async {
    final userSales = _sales.where((sale) => sale.userId == userId).toList();
    final Map<int, Map<String, dynamic>> productStats = {};
    
    for (final sale in userSales) {
      if (sale.id != null) {
        final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
        for (final line in saleLines) {
          if (productStats.containsKey(line.productId)) {
            productStats[line.productId]!['quantity'] += line.quantity!;
          } else {
            productStats[line.productId!] = {
              'name': _productNames[line.productId] ?? 'Produit inconnu',
              'quantity': line.quantity!,
            };
          }
        }
      }
    }
    
    final sortedProducts = productStats.values.toList();
    sortedProducts.sort((a, b) => b['quantity'].compareTo(a['quantity']));
    return sortedProducts;
  }

  Widget _buildUserReportCard(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userSales = _sales.where((sale) => sale.userId == user.id).toList();
    final totalUserSales = userSales.fold(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role ?? 'vendeur'),
                  child: Text(
                    (user.fullName ?? user.username ?? '').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? user.username ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.role ?? 'vendeur',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getRoleColor(user.role ?? 'vendeur'),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${userSales.length} ventes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${totalUserSales.toStringAsFixed(0)} GNF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (userSales.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Dernières ventes:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...userSales.take(3).map((sale) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      sale.saleDate?.substring(0, 10) ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'gestionnaire':
        return Colors.blue;
      case 'caissier':
        return Colors.green;
      case 'vendeur':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showSaleDetails(Sale sale) async {
    final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de la vente #${sale.id}'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${sale.saleDate}'),
              Text('Client: ${_customerNames[sale.customerId] ?? 'Client direct'}'),
              Text('Utilisateur: ${_userNames[sale.userId] ?? 'Inconnu'}'),
              Text('Type de paiement: ${sale.paymentType ?? 'direct'}'),
              const SizedBox(height: 16),
              const Text('Produits vendus:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...saleLines.map((line) => Card(
                child: ListTile(
                  title: Text(_productNames[line.productId] ?? 'Produit inconnu'),
                  subtitle: Text('Prix unitaire: ${line.salePrice} GNF'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Qté: ${line.quantity}'),
                      Text('${line.subtotal} GNF', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${sale.totalAmount} GNF', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPurchaseDetails(Purchase purchase) async {
    final purchaseLines = await DatabaseHelper.instance.getPurchaseLines(purchase.id!);
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de l\'achat #${purchase.id}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...purchaseLines.map((line) => ListTile(
                title: Text(_productNames[line.productId] ?? 'Produit inconnu'),
                subtitle: Text('Quantité: ${line.quantity} × ${line.purchasePrice} GNF'),
                trailing: Text('${line.subtotal} GNF'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSalesReport(String format) async {
    if (format == 'pdf') {
      await _generateSalesPDF();
    } else {
      await _generateSalesExcel();
    }
  }

  Future<void> _exportPurchasesReport(String format) async {
    if (format == 'pdf') {
      await _generatePurchasesPDF();
    } else {
      await _generatePurchasesExcel();
    }
  }

  Future<void> _exportUsersReport(String format) async {
    if (format == 'pdf') {
      await _generateUsersPDF();
    } else {
      await _generateUsersExcel();
    }
  }

  Future<void> _generateSalesPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rapport des Ventes', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Client', 'Utilisateur', 'Montant', 'Type'],
                data: _sales.map((sale) => [
                  sale.saleDate?.substring(0, 10) ?? '',
                  _customerNames[sale.customerId] ?? 'Client direct',
                  _userNames[sale.userId] ?? 'Inconnu',
                  '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                  sale.paymentType ?? 'direct',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _generatePurchasesPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rapport des Achats', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Fournisseur', 'Utilisateur', 'Montant', 'Type'],
                data: _purchases.map((purchase) => [
                  purchase.purchaseDate?.substring(0, 10) ?? '',
                  _supplierNames[purchase.supplierId] ?? 'Inconnu',
                  _userNames[purchase.userId] ?? 'Inconnu',
                  '${(purchase.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                  purchase.paymentType ?? 'direct',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _generateUsersPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rapport des Utilisateurs', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Nom', 'Rôle', 'Ventes', 'Total Vendu'],
                data: _users.map((user) {
                  final userSales = _sales.where((sale) => sale.userId == user.id).toList();
                  final totalUserSales = userSales.fold(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0));
                  return [
                    user.fullName ?? user.username ?? '',
                    user.role ?? 'vendeur',
                    '${userSales.length}',
                    '${totalUserSales.toStringAsFixed(0)} GNF',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _generateSalesExcel() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Sauvegarder le rapport des ventes',
      fileName: 'rapport_ventes_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    if (result != null) {
      final file = File(result);
      final csv = StringBuffer();
      csv.writeln('Date,Client,Utilisateur,Montant,Type');
      
      for (final sale in _sales) {
        csv.writeln([
          sale.saleDate?.substring(0, 10) ?? '',
          _customerNames[sale.customerId] ?? 'Client direct',
          _userNames[sale.userId] ?? 'Inconnu',
          (sale.totalAmount ?? 0).toStringAsFixed(0),
          sale.paymentType ?? 'direct',
        ].join(','));
      }
      
      await file.writeAsString(csv.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport exporté avec succès')),
        );
      }
    }
  }

  Future<void> _generatePurchasesExcel() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Sauvegarder le rapport des achats',
      fileName: 'rapport_achats_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    if (result != null) {
      final file = File(result);
      final csv = StringBuffer();
      csv.writeln('Date,Fournisseur,Utilisateur,Montant,Type');
      
      for (final purchase in _purchases) {
        csv.writeln([
          purchase.purchaseDate?.substring(0, 10) ?? '',
          _supplierNames[purchase.supplierId] ?? 'Inconnu',
          _userNames[purchase.userId] ?? 'Inconnu',
          (purchase.totalAmount ?? 0).toStringAsFixed(0),
          purchase.paymentType ?? 'direct',
        ].join(','));
      }
      
      await file.writeAsString(csv.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport exporté avec succès')),
        );
      }
    }
  }

  Future<void> _generateUsersExcel() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Sauvegarder le rapport des utilisateurs',
      fileName: 'rapport_utilisateurs_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    if (result != null) {
      final file = File(result);
      final csv = StringBuffer();
      csv.writeln('Nom,Role,Ventes,Total_Vendu');
      
      for (final user in _users) {
        final userSales = _sales.where((sale) => sale.userId == user.id).toList();
        final totalUserSales = userSales.fold(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0));
        csv.writeln([
          user.fullName ?? user.username ?? '',
          user.role ?? 'vendeur',
          userSales.length,
          totalUserSales.toStringAsFixed(0),
        ].join(','));
      }
      
      await file.writeAsString(csv.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport exporté avec succès')),
        );
      }
    }
  }
}