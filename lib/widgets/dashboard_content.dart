import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../core/database/database_helper.dart';

/// Dashboard professionnel optimisé pour Desktop sans overflow
class DashboardContent extends StatefulWidget {
  final User currentUser;

  const DashboardContent({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  Map<String, dynamic> _kpis = {};
  List<FlSpot> _salesChart = [];
  List<ProductSalesData> _topProducts = [];
  List<Product> _lowStockProducts = [];
  List<Sale> _creditSales = [];
  List<Sale> _recentSales = [];
  List<UserSalesData> _topUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadKPIs(),
        _loadSalesChart(),
        _loadProductsData(),
        _loadAlertsData(),
        _loadRecentActivities(),
        _loadTopUsers(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadKPIs() async {
    final products = await DatabaseHelper.instance.getProducts();
    final sales = await DatabaseHelper.instance.getSales();
    
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    
    final recentSales = sales.where((sale) {
      if (sale.saleDate == null) return false;
      final saleDate = DateTime.parse(sale.saleDate!);
      return saleDate.isAfter(threeDaysAgo);
    }).toList();
    
    final creditSales = sales.where((sale) => sale.paymentType == 'credit').toList();
    
    double totalRevenue = recentSales.fold(0, (sum, sale) => sum + (sale.totalAmount ?? 0));
    double totalCost = 0;
    
    for (final sale in recentSales) {
      final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
      for (final line in saleLines) {
        final product = await DatabaseHelper.instance.getProduct(line.productId!);
        if (product != null) {
          totalCost += (product.purchasePrice ?? 0) * (line.quantity ?? 0);
        }
      }
    }
    
    _kpis = {
      'totalProducts': products.length,
      'recentSalesCount': recentSales.length,
      'recentRevenue': totalRevenue,
      'recentProfit': totalRevenue - totalCost,
      'creditSalesCount': creditSales.length,
    };
  }

  Future<void> _loadSalesChart() async {
    final sales = await DatabaseHelper.instance.getSales();
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      double dayTotal = 0;
      for (final sale in sales) {
        if (sale.saleDate != null) {
          final saleDate = DateTime.parse(sale.saleDate!);
          if (saleDate.isAfter(dayStart) && saleDate.isBefore(dayEnd)) {
            dayTotal += sale.totalAmount ?? 0;
          }
        }
      }
      spots.add(FlSpot((6 - i).toDouble(), dayTotal));
    }
    
    _salesChart = spots;
  }

  Future<void> _loadProductsData() async {
    final products = await DatabaseHelper.instance.getProducts();
    final sales = await DatabaseHelper.instance.getSales();
    final productSales = <int, int>{};
    
    for (final sale in sales) {
      final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
      for (final line in saleLines) {
        productSales[line.productId!] = (productSales[line.productId!] ?? 0) + (line.quantity ?? 0);
      }
    }
    
    final productSalesData = products.map((product) {
      final soldQuantity = productSales[product.id] ?? 0;
      return ProductSalesData(product.name, soldQuantity);
    }).toList();
    
    productSalesData.sort((a, b) => b.quantity.compareTo(a.quantity));
    _topProducts = productSalesData.take(5).toList();
  }

  Future<void> _loadAlertsData() async {
    final products = await DatabaseHelper.instance.getProducts();
    final sales = await DatabaseHelper.instance.getSales();
    
    _lowStockProducts = products.where((product) {
      final threshold = product.stockAlertThreshold ?? 10;
      return (product.stockQuantity ?? 0) <= threshold;
    }).toList();
    
    final now = DateTime.now();
    final oneWeekFromNow = now.add(const Duration(days: 7));
    
    _creditSales = sales.where((sale) {
      if (sale.paymentType != 'credit' || sale.dueDate == null) return false;
      final dueDate = DateTime.parse(sale.dueDate!);
      return dueDate.isBefore(oneWeekFromNow) && dueDate.isAfter(now);
    }).toList();
  }

  Future<void> _loadRecentActivities() async {
    final sales = await DatabaseHelper.instance.getSales();
    sales.sort((a, b) {
      if (a.saleDate == null && b.saleDate == null) return 0;
      if (a.saleDate == null) return 1;
      if (b.saleDate == null) return -1;
      return DateTime.parse(b.saleDate!).compareTo(DateTime.parse(a.saleDate!));
    });
    _recentSales = sales.take(5).toList();
  }

  Future<void> _loadTopUsers() async {
    final sales = await DatabaseHelper.instance.getSales();
    final users = await DatabaseHelper.instance.getUsers();
    final userSales = <int, double>{};
    
    for (final sale in sales) {
      if (sale.userId != null) {
        userSales[sale.userId!] = (userSales[sale.userId!] ?? 0) + (sale.totalAmount ?? 0);
      }
    }
    
    final userSalesData = <UserSalesData>[];
    for (final user in users) {
      final totalSales = userSales[user.id] ?? 0;
      if (totalSales > 0) {
        userSalesData.add(UserSalesData(
          user.fullName ?? user.username,
          totalSales,
        ));
      }
    }
    
    userSalesData.sort((a, b) => b.totalSales.compareTo(a.totalSales));
    _topUsers = userSalesData.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - hauteur fixe
              _buildHeader(context),
              const SizedBox(height: 16),
              
              // KPIs - hauteur fixe
              _buildKPIsSection(),
              const SizedBox(height: 20),
              
              // Graphiques - hauteur flexible
              _buildChartsSection(constraints),
              const SizedBox(height: 20),
              
              // Alertes et activités - hauteur flexible
              _buildAlertsAndActivitiesSection(constraints),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tableau de Bord',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   'Bienvenue, ${widget.currentUser.fullName ?? widget.currentUser.username}',
                    //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    //     color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    //   ),
                    // ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Actualiser'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs Clés',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Produits',
                  _kpis['totalProducts']?.toString() ?? '0',
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Ventes (3j)',
                  _kpis['recentSalesCount']?.toString() ?? '0',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Revenus (3j)',
                  '${(_kpis['recentRevenue'] ?? 0).toStringAsFixed(0)} GNF',
                  Icons.attach_money,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Bénéfices (3j)',
                  '${(_kpis['recentProfit'] ?? 0).toStringAsFixed(0)} GNF',
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Crédit',
                  _kpis['creditSalesCount']?.toString() ?? '0',
                  Icons.credit_card,
                  Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection(BoxConstraints constraints) {
    final chartHeight = (constraints.maxHeight * 0.3).clamp(200.0, 280.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Analyses des Ventes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: chartHeight,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSalesChart(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTopProductsChart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsAndActivitiesSection(BoxConstraints constraints) {
    final sectionHeight = (constraints.maxHeight * 0.25).clamp(180.0, 250.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Alertes et Activités',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: sectionHeight,
          child: Row(
            children: [
              Expanded(child: _buildAlertsCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildRecentActivitiesCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildTopUsersCard()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    final maxY = _salesChart.isNotEmpty 
        ? _salesChart.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2
        : 100000.0;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ventes 7 derniers jours',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(0)} GNF',
                          const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final now = DateTime.now();
                          final date = now.subtract(Duration(days: (6 - value.toInt())));
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1000000) {
                            return Text('${(value / 1000000).toStringAsFixed(1)}M', 
                              style: const TextStyle(fontSize: 8));
                          } else if (value >= 1000) {
                            return Text('${(value / 1000).toStringAsFixed(0)}k', 
                              style: const TextStyle(fontSize: 8));
                          }
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 8));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                  ),
                  barGroups: _salesChart.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.y,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 5 Produits',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _topProducts.isEmpty
                  ? const Center(child: Text('Aucune donnée'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _topProducts.first.quantity.toDouble() * 1.2,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < _topProducts.length) {
                                  final name = _topProducts[value.toInt()].name;
                                  return Text(
                                    name.length > 6 ? '${name.substring(0, 6)}...' : name,
                                    style: const TextStyle(fontSize: 8),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}',
                                style: const TextStyle(fontSize: 8),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _topProducts.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.quantity.toDouble(),
                                color: Colors.green,
                                width: 16,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(2),
                                  topRight: Radius.circular(2),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Alertes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_lowStockProducts.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Stock Critique (${_lowStockProducts.length})',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ...(_lowStockProducts.take(2).map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Text(
                                '• ${product.name} (${product.stockQuantity ?? 0})',
                                style: const TextStyle(fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (_creditSales.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dettes échéance (${_creditSales.length})',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ...(_creditSales.take(2).map((sale) => Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Text(
                                '• Vente #${sale.id} - ${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                                style: const TextStyle(fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))),
                          ],
                        ),
                      ),
                    ],
                    if (_lowStockProducts.isEmpty && _creditSales.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Aucune alerte',
                          style: TextStyle(fontSize: 10),
                        ),
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

  Widget _buildRecentActivitiesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Activités Récentes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _recentSales.isEmpty
                  ? const Center(child: Text('Aucune activité', style: TextStyle(fontSize: 10)))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _recentSales.length,
                      separatorBuilder: (context, index) => const Divider(height: 6),
                      itemBuilder: (context, index) {
                        final sale = _recentSales[index];
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.green.withValues(alpha: 0.2),
                              child: const Icon(Icons.shopping_cart, size: 10, color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Vente #${sale.id}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatDateTime(sale.saleDate),
                                    style: const TextStyle(fontSize: 8),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsersCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Top Vendeurs',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _topUsers.isEmpty
                  ? const Center(child: Text('Aucun vendeur', style: TextStyle(fontSize: 10)))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _topUsers.length,
                      separatorBuilder: (context, index) => const Divider(height: 6),
                      itemBuilder: (context, index) {
                        final user = _topUsers[index];
                        final isCurrentUser = user.name == (widget.currentUser.fullName ?? widget.currentUser.username);
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: isCurrentUser 
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentUser ? Colors.blue : Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrentUser ? Colors.blue : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${user.totalSales.toStringAsFixed(0)} GNF',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser ? Colors.blue : Colors.green,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return 'Il y a ${difference.inMinutes}min';
      }
    } catch (e) {
      return dateString;
    }
  }
}

class ProductSalesData {
  final String name;
  final int quantity;

  ProductSalesData(this.name, this.quantity);
}

class UserSalesData {
  final String name;
  final double totalSales;

  UserSalesData(this.name, this.totalSales);
}