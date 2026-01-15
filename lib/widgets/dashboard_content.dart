import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../core/database/database_helper.dart';

/// Dashboard professionnel optimisé pour Desktop sans overflow
class DashboardContent extends StatefulWidget {
  final User currentUser;

  const DashboardContent({Key? key, required this.currentUser})
    : super(key: key);

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

    final creditSales = sales
        .where((sale) => sale.paymentType == 'credit')
        .toList();

    double totalRevenue = recentSales.fold(
      0,
      (sum, sale) => sum + (sale.totalAmount ?? 0),
    );
    double totalCost = 0;

    for (final sale in recentSales) {
      if (sale.id != null) {
        final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
        for (final line in saleLines) {
          final product = await DatabaseHelper.instance.getProduct(
            line.productId,
          );
          if (product != null) {
            totalCost += (product.purchasePrice ?? 0) * (line.quantity ?? 0);
          }
        }
      }
    }

    _kpis = {
      'totalProducts': products.length,
      'recentSalesCount': recentSales.length,
      'recentRevenue': totalRevenue,
      'recentProfit': totalRevenue - totalCost,
      'creditSalesCount': creditSales.length,
      'lowStockCount': products
          .where((p) => (p.stockQuantity ?? 0) <= (p.stockAlertThreshold ?? 10))
          .length,
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

    if (mounted) {
      setState(() {
        _salesChart = spots;
      });
    }
  }

  Future<void> _loadProductsData() async {
    final products = await DatabaseHelper.instance.getProducts();
    final sales = await DatabaseHelper.instance.getSales();
    final productSales = <int, int>{};

    for (final sale in sales) {
      if (sale.id != null) {
        final saleLines = await DatabaseHelper.instance.getSaleLines(sale.id!);
        for (final line in saleLines) {
          // line.productId is likely non-nullable based on lints
          productSales[line.productId] =
              (productSales[line.productId] ?? 0) + (line.quantity ?? 0);
        }
      }
    }

    final productSalesData = products.map((product) {
      final soldQuantity = productSales[product.id] ?? 0;
      return ProductSalesData(product.name, soldQuantity);
    }).toList();

    productSalesData.sort((a, b) => b.quantity.compareTo(a.quantity));

    if (mounted) {
      setState(() {
        _topProducts = productSalesData.take(5).toList();
      });
    }
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
        userSales[sale.userId!] =
            (userSales[sale.userId!] ?? 0) + (sale.totalAmount ?? 0);
      }
    }

    final userSalesData = <UserSalesData>[];
    for (final user in users) {
      final totalSales = userSales[user.id] ?? 0;
      if (totalSales > 0) {
        userSalesData.add(
          UserSalesData(user.fullName ?? user.username, totalSales),
        );
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
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(context, isMobile),
              SizedBox(height: isMobile ? 8 : 16),

              // KPIs
              _buildKPIsSection(isMobile),
              SizedBox(height: isMobile ? 12 : 20),

              // Graphiques
              _buildChartsSection(constraints, isMobile),
              SizedBox(height: isMobile ? 12 : 20),

              // Alertes et activités
              _buildAlertsAndActivitiesSection(constraints, isMobile),
              SizedBox(height: isMobile ? 8 : 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return SizedBox(
      height: isMobile ? 60 : 80,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tableau de Bord',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 18 : null,
                          ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: Icon(Icons.refresh, size: isMobile ? 14 : 16),
                label: Text(isMobile ? 'Actualiser' : 'Actualiser'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 6 : 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs Clés',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : null,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        isMobile ? _buildMobileKPIs() : _buildDesktopKPIs(),
      ],
    );
  }

  Widget _buildDesktopKPIs() {
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard(
              'Produits',
              _kpis['totalProducts']?.toString() ?? '0',
              Icons.inventory_2,
              Colors.blue,
              false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKPICard(
              'Ventes (3j)',
              _kpis['recentSalesCount']?.toString() ?? '0',
              Icons.trending_up,
              Colors.green,
              false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKPICard(
              'Revenus (3j)',
              '${(_kpis['recentRevenue'] ?? 0).toStringAsFixed(0)} GNF',
              Icons.attach_money,
              Colors.orange,
              false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKPICard(
              'Bénéfices (3j)',
              '${(_kpis['recentProfit'] ?? 0).toStringAsFixed(0)} GNF',
              Icons.account_balance_wallet,
              Colors.purple,
              false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKPICard(
              'Crédit',
              _kpis['creditSalesCount']?.toString() ?? '0',
              Icons.credit_card,
              Colors.red,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileKPIs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Produits',
                _kpis['totalProducts']?.toString() ?? '0',
                Icons.inventory_2,
                Colors.blue,
                true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKPICard(
                'Ventes (3j)',
                _kpis['recentSalesCount']?.toString() ?? '0',
                Icons.trending_up,
                Colors.green,
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Revenus (3j)',
                '${(_kpis['recentRevenue'] ?? 0).toStringAsFixed(0)} GNF',
                Icons.attach_money,
                Colors.orange,
                true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKPICard(
                'Crédit',
                _kpis['creditSalesCount']?.toString() ?? '0',
                Icons.credit_card,
                Colors.red,
                true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartsSection(BoxConstraints constraints, bool isMobile) {
    final chartHeight = isMobile
        ? 200.0
        : (constraints.maxHeight * 0.3).clamp(200.0, 280.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Analyses des Ventes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : null,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        isMobile
            ? _buildMobileCharts(chartHeight)
            : _buildDesktopCharts(chartHeight),
      ],
    );
  }

  Widget _buildDesktopCharts(double chartHeight) {
    return SizedBox(
      height: chartHeight,
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildSalesChart()),
          const SizedBox(width: 12),
          Expanded(child: _buildTopProductsChart()),
        ],
      ),
    );
  }

  Widget _buildMobileCharts(double chartHeight) {
    return Column(
      children: [
        SizedBox(height: chartHeight, child: _buildSalesChart()),
        const SizedBox(height: 12),
        SizedBox(height: chartHeight, child: _buildTopProductsChart()),
      ],
    );
  }

  Widget _buildAlertsAndActivitiesSection(
    BoxConstraints constraints,
    bool isMobile,
  ) {
    final sectionHeight = isMobile
        ? 180.0
        : (constraints.maxHeight * 0.25).clamp(180.0, 250.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Alertes et Activités',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : null,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        isMobile
            ? _buildMobileAlertsAndActivities(sectionHeight)
            : _buildDesktopAlertsAndActivities(sectionHeight),
      ],
    );
  }

  Widget _buildDesktopAlertsAndActivities(double sectionHeight) {
    return SizedBox(
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
    );
  }

  Widget _buildMobileAlertsAndActivities(double sectionHeight) {
    return Column(
      children: [
        SizedBox(height: sectionHeight, child: _buildAlertsCard()),
        const SizedBox(height: 12),
        SizedBox(height: sectionHeight, child: _buildRecentActivitiesCard()),
        const SizedBox(height: 12),
        SizedBox(height: sectionHeight, child: _buildTopUsersCard()),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    // Utiliser les couleurs du thème si possible, sinon garder la couleur sémantique mais ajustée
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      height: isMobile ? 110 : null,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: isMobile ? 18 : 20, color: color),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: isMobile ? 14 : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isMobile ? 10 : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    final theme = Theme.of(context);
    final maxY = _salesChart.isNotEmpty
        ? _salesChart.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2
        : 100000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ventes 7 derniers jours',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.bar_chart,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)} GNF',
                        TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final now = DateTime.now();
                        final date = now.subtract(
                          Duration(days: (6 - value.toInt())),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value >= 1000000
                              ? '${(value / 1000000).toStringAsFixed(1)}M'
                              : '${(value / 1000).toStringAsFixed(0)}k',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: _salesChart.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.y,
                        color: theme.colorScheme.primary,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
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
    );
  }

  Widget _buildTopProductsChart() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top 5 Produits',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.pie_chart,
                color: theme.colorScheme.secondary.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _topProducts.isEmpty
                ? Center(
                    child: Text(
                      'Aucune donnée',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _topProducts.first.quantity.toDouble() * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              theme.colorScheme.inverseSurface,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              _topProducts[group.x.toInt()].name,
                              TextStyle(
                                color: theme.colorScheme.onInverseSurface,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < _topProducts.length) {
                                final name = _topProducts[value.toInt()].name;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    name.length > 6
                                        ? '${name.substring(0, 6)}...'
                                        : name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
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
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.dividerColor.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: _topProducts.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.quantity.toDouble(),
                              color: theme.colorScheme.secondary,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY:
                                    _topProducts.first.quantity.toDouble() *
                                    1.2,
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.3),
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
    );
  }

  Widget _buildAlertsCard() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Alertes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_lowStockProducts.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Stock Critique (${_lowStockProducts.length})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(_lowStockProducts
                              .take(3)
                              .map(
                                (product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 4,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${product.name}',
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${product.stockQuantity ?? 0}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.error,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_creditSales.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Dettes à échéance (${_creditSales.length})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(_creditSales
                              .take(3)
                              .map(
                                (sale) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 4,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Vente #${sale.id}',
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                  if (_lowStockProducts.isEmpty && _creditSales.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 32,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tout est en ordre',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildRecentActivitiesCard() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Activités Récentes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _recentSales.isEmpty
                ? Center(
                    child: Text(
                      'Aucune activité',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _recentSales.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 16,
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                    itemBuilder: (context, index) {
                      final sale = _recentSales[index];
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Vente #${sale.id}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatDateTime(sale.saleDate),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                            style: theme.textTheme.bodyMedium?.copyWith(
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
    );
  }

  Widget _buildTopUsersCard() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Top Vendeurs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _topUsers.isEmpty
                ? Center(
                    child: Text(
                      'Aucun vendeur',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _topUsers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 16,
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                    itemBuilder: (context, index) {
                      final user = _topUsers[index];
                      final isCurrentUser =
                          user.name ==
                          (widget.currentUser.fullName ??
                              widget.currentUser.username);

                      return Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrentUser
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${user.totalSales.toStringAsFixed(0)} GNF',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser
                                  ? theme.colorScheme.primary
                                  : Colors.green,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
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
