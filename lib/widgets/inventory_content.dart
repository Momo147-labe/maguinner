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

  const InventoryContent({Key? key, required this.currentUser})
    : super(key: key);

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
          final product = await DatabaseHelper.instance.getProduct(
            line.productId!,
          );
          if (product != null) {
            final profit =
                (line.salePrice! - (product.purchasePrice ?? 0)) *
                line.quantity!;
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
    final lowStockProducts = products
        .where((p) => (p.stockQuantity ?? 0) <= (p.stockAlertThreshold ?? 10))
        .length;

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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.warehouse_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventaire',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Vue d\'ensemble',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadInventoryData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Actualiser'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.warehouse_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventaire & Santé du Magasin',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vue d\'ensemble complète de votre business',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _loadInventoryData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualiser'),
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
          );
        },
      ),
    );
  }

  Widget _buildMainKPIs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs Financiers',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            if (isMobile) {
              return Column(
                children: [
                  _buildKPICard(
                    'Bénéfices Totaux',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['totalProfit'] ?? 0,
                    ),
                    Icons.trending_up,
                    Colors.green,
                    subtitle:
                        '${(_inventoryData['profitMargin'] ?? 0).toStringAsFixed(1)}% marge',
                  ),
                  const SizedBox(height: 16),
                  _buildKPICard(
                    'Ventes Totales',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['totalSales'] ?? 0,
                    ),
                    Icons.point_of_sale,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildKPICard(
                    'Valeur du Stock',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['stockValue'] ?? 0,
                    ),
                    Icons.inventory_2_rounded,
                    Colors.purple,
                    subtitle:
                        '${_inventoryData['totalStockQuantity'] ?? 0} articles',
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'Bénéfices Totaux',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['totalProfit'] ?? 0,
                    ),
                    Icons.trending_up_rounded,
                    Colors.green,
                    subtitle:
                        '${(_inventoryData['profitMargin'] ?? 0).toStringAsFixed(1)}% marge',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Ventes Totales',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['totalSales'] ?? 0,
                    ),
                    Icons.point_of_sale_rounded,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Valeur du Stock',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['stockValue'] ?? 0,
                    ),
                    Icons.inventory_2_rounded,
                    Colors.purple,
                    subtitle:
                        '${_inventoryData['totalStockQuantity'] ?? 0} articles',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            if (isMobile) {
              return Column(
                children: [
                  _buildKPICard(
                    'Créances Clients',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['clientDebts'] ?? 0,
                    ),
                    Icons.account_balance_wallet_rounded,
                    Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  _buildKPICard(
                    'Dettes Fournisseurs',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['supplierDebts'] ?? 0,
                    ),
                    Icons.credit_card_rounded,
                    Colors.orange,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'Créances Clients',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['clientDebts'] ?? 0,
                    ),
                    Icons.account_balance_wallet_rounded,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Dettes Fournisseurs',
                    CurrencyFormatter.formatGNF(
                      _inventoryData['supplierDebts'] ?? 0,
                    ),
                    Icons.credit_card_rounded,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Alertes Stock',
                    '${_inventoryData['lowStockProducts'] ?? 0}',
                    Icons.warning_amber_rounded,
                    Colors.red,
                    subtitle: 'Produits faibles',
                  ),
                ),
              ],
            );
          },
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            if (isMobile) {
              return Column(
                children: [
                  SizedBox(height: 300, child: _buildProfitChart()),
                  const SizedBox(height: 16),
                  SizedBox(height: 300, child: _buildDebtsPieChart()),
                ],
              );
            }
            return SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(flex: 2, child: _buildProfitChart()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDebtsPieChart()),
                ],
              ),
            );
          },
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            if (isMobile) {
              return Column(
                children: [
                  _buildKPICard(
                    'Produits en Stock',
                    '${_inventoryData['totalProducts'] ?? 0}',
                    Icons.category_rounded,
                    Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                  _buildKPICard(
                    'Quantité Totale',
                    '${_inventoryData['totalStockQuantity'] ?? 0}',
                    Icons.shopping_bag_rounded,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildKPICard(
                    'Pertes Estimées',
                    CurrencyFormatter.formatGNF(_inventoryData['losses'] ?? 0),
                    Icons.trending_down_rounded,
                    Colors.red,
                    subtitle: 'Casse / Expiration',
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'Produits en Stock',
                    '${_inventoryData['totalProducts'] ?? 0}',
                    Icons.category_rounded,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Quantité Totale',
                    '${_inventoryData['totalStockQuantity'] ?? 0}',
                    Icons.shopping_bag_rounded,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Pertes Estimées',
                    CurrencyFormatter.formatGNF(_inventoryData['losses'] ?? 0),
                    Icons.trending_down_rounded,
                    Colors.red,
                    subtitle: 'Casse / Expiration',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfitChart() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ventes vs Achats',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      [
                        _inventoryData['totalSales'] ?? 0,
                        _inventoryData['totalPurchases'] ?? 0,
                      ].reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          theme.colorScheme.surfaceContainerHighest,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toStringAsFixed(0),
                          TextStyle(color: theme.colorScheme.onSurface),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          );
                          switch (value.toInt()) {
                            case 0:
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Ventes',
                                  style: style.copyWith(color: Colors.green),
                                ),
                              );
                            case 1:
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Achats',
                                  style: style.copyWith(color: Colors.orange),
                                ),
                              );
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: (_inventoryData['totalSales'] ?? 0).toDouble(),
                          color: Colors.green,
                          width: 50,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY:
                                [
                                  _inventoryData['totalSales'] ?? 0,
                                  _inventoryData['totalPurchases'] ?? 0,
                                ].reduce((a, b) => a > b ? a : b) *
                                1.2,
                            color: Colors.green.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: (_inventoryData['totalPurchases'] ?? 0)
                              .toDouble(),
                          color: Colors.orange,
                          width: 50,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY:
                                [
                                  _inventoryData['totalSales'] ?? 0,
                                  _inventoryData['totalPurchases'] ?? 0,
                                ].reduce((a, b) => a > b ? a : b) *
                                1.2,
                            color: Colors.orange.withOpacity(0.05),
                          ),
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
    final theme = Theme.of(context);
    final clientDebts = (_inventoryData['clientDebts'] ?? 0).toDouble();
    final supplierDebts = (_inventoryData['supplierDebts'] ?? 0).toDouble();
    final total = clientDebts + supplierDebts;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition des Dettes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: total > 0
                  ? PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.teal,
                            value: clientDebts,
                            title:
                                '${(clientDebts / total * 100).toStringAsFixed(0)}%',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            badgeWidget: _buildBadge(
                              'Clients',
                              Colors.teal,
                              CurrencyFormatter.formatGNF(clientDebts),
                            ),
                            badgePositionPercentageOffset: 1.3,
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: supplierDebts,
                            title:
                                '${(supplierDebts / total * 100).toStringAsFixed(0)}%',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            badgeWidget: _buildBadge(
                              'Fournisseurs',
                              Colors.orange,
                              CurrencyFormatter.formatGNF(supplierDebts),
                            ),
                            badgePositionPercentageOffset: 1.3,
                          ),
                        ],
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aucune dette',
                            style: theme.textTheme.bodyLarge,
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

  Widget _buildBadge(String title, Color color, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Text(amount, style: TextStyle(color: color, fontSize: 8)),
        ],
      ),
    );
  }
}
