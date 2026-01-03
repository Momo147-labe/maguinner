import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../core/database/database_helper.dart';
import '../utils/currency_formatter.dart';

/// Inventaire complet - Cœur du magasin
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
  Map<String, dynamic> _inventoryData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _calculateInventoryMetrics();
      if (mounted) {
        setState(() {
          _inventoryData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _calculateInventoryMetrics() async {
    final products = await DatabaseHelper.instance.getProducts();
    final sales = await DatabaseHelper.instance.getSales();
    final purchases = await DatabaseHelper.instance.getPurchases();
    final suppliers = await DatabaseHelper.instance.getSuppliers();

    double totalSales = 0;
    double totalPurchases = 0;
    double totalProfit = 0;
    double clientDebts = 0;
    double supplierDebts = 0;
    double stockValue = 0;
    double losses = 0;
    int totalStockQuantity = 0;

    // Calcul des ventes totales et dettes clients
    for (final sale in sales) {
      totalSales += sale.totalAmount ?? 0;
      if (sale.paymentType == 'credit') {
        clientDebts += sale.totalAmount ?? 0;
      }
    }

    // Calcul du bénéfice réel basé sur les lignes de vente
    for (final sale in sales) {
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

    // Achats totaux
    for (final purchase in purchases) {
      totalPurchases += purchase.totalAmount ?? 0;
    }

    // Dettes fournisseurs
    for (final supplier in suppliers) {
      supplierDebts += supplier.balance ?? 0;
    }

    // Stock actuel et valeur
    for (final product in products) {
      final quantity = product.stockQuantity ?? 0;
      final price = product.purchasePrice ?? 0;
      totalStockQuantity += quantity;
      stockValue += quantity * price;
    }

    // Estimation des pertes (2% du stock)
    losses = stockValue * 0.02;

    // Produits en alerte
    final lowStockProducts = products.where((p) => 
      (p.stockQuantity ?? 0) <= (p.stockAlertThreshold ?? 10)
    ).length;

    return {
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'totalProfit': totalProfit,
      'clientDebts': clientDebts,
      'supplierDebts': supplierDebts,
      'stockValue': stockValue,
      'losses': losses,
      'totalStockQuantity': totalStockQuantity,
      'lowStockProducts': lowStockProducts,
      'totalProducts': products.length,
      'profitMargin': totalSales > 0 ? (totalProfit / totalSales) * 100 : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMainKPIs(),
          const SizedBox(height: 24),
          _buildFinancialCharts(),
          const SizedBox(height: 24),
          _buildStockSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.warehouse, color: Colors.green.shade700, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventaire & Santé du Magasin',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Vue d\'ensemble complète de votre business',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _loadInventoryData,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMainKPIs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs Financiers',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Bénéfices Totaux',
                CurrencyFormatter.formatGNF(_inventoryData['totalProfit'] ?? 0),
                Icons.trending_up,
                Colors.green,
                subtitle: '${(_inventoryData['profitMargin'] ?? 0).toStringAsFixed(1)}% marge',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Ventes Totales',
                CurrencyFormatter.formatGNF(_inventoryData['totalSales'] ?? 0),
                Icons.point_of_sale,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Achats Totaux',
                CurrencyFormatter.formatGNF(_inventoryData['totalPurchases'] ?? 0),
                Icons.shopping_cart,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Valeur du Stock',
                CurrencyFormatter.formatGNF(_inventoryData['stockValue'] ?? 0),
                Icons.inventory,
                Colors.purple,
                subtitle: '${_inventoryData['totalStockQuantity'] ?? 0} articles',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Créances Clients',
                CurrencyFormatter.formatGNF(_inventoryData['clientDebts'] ?? 0),
                Icons.account_balance_wallet,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Dettes Fournisseurs',
                CurrencyFormatter.formatGNF(_inventoryData['supplierDebts'] ?? 0),
                Icons.credit_card,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Pertes Estimées',
                CurrencyFormatter.formatGNF(_inventoryData['losses'] ?? 0),
                Icons.trending_down,
                Colors.red.shade700,
                subtitle: 'Casse, expiration',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Alertes Stock',
                '${_inventoryData['lowStockProducts'] ?? 0}',
                Icons.warning,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyse Financière',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildProfitChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebtsPieChart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État du Stock',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Produits en Stock',
                '${_inventoryData['totalProducts'] ?? 0}',
                Icons.category,
                Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Quantité Totale',
                '${_inventoryData['totalStockQuantity'] ?? 0}',
                Icons.inventory_2,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Valeur du Stock',
                CurrencyFormatter.formatGNF(_inventoryData['stockValue'] ?? 0),
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
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
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfitChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ventes vs Achats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: [_inventoryData['totalSales'] ?? 0, _inventoryData['totalPurchases'] ?? 0]
                      .reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Text('Ventes', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54));
                            case 1:
                              return Text('Achats', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: _inventoryData['totalSales']?.toDouble() ?? 0,
                          color: Colors.green,
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: _inventoryData['totalPurchases']?.toDouble() ?? 0,
                          color: Colors.orange,
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsPieChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clientDebts = _inventoryData['clientDebts']?.toDouble() ?? 0;
    final supplierDebts = _inventoryData['supplierDebts']?.toDouble() ?? 0;
    final total = clientDebts + supplierDebts;
    
    return Card(
      elevation: 4,
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créances & Dettes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: total > 0 ? PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.teal,
                      value: clientDebts,
                      title: 'Clients\n${(clientDebts / total * 100).toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: supplierDebts,
                      title: 'Fournisseurs\n${(supplierDebts / total * 100).toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ) : Center(
                child: Text(
                  'Aucune dette',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}