import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/product.dart';
import '../models/sale.dart';

import '../models/supplier.dart';
import '../utils/currency_formatter.dart';

class AlertsWidget extends StatefulWidget {
  final Color? iconColor;

  const AlertsWidget({Key? key, this.iconColor}) : super(key: key);

  @override
  State<AlertsWidget> createState() => _AlertsWidgetState();
}

class _AlertsWidgetState extends State<AlertsWidget> {
  int _alertCount = 0;
  List<Product> _lowStockProducts = [];
  List<Product> _lowSalesProducts = [];
  List<Sale> _unpaidSales = [];
  List<Supplier> _suppliersWithDebt = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final products = await DatabaseHelper.instance.getProducts();
      final sales = await DatabaseHelper.instance.getSales();
      final suppliers = await DatabaseHelper.instance.getSuppliers();

      // Produits en rupture de stock
      final lowStock = products
          .where((p) => (p.stockQuantity ?? 0) <= (p.stockAlertThreshold ?? 10))
          .toList();

      // Produits les moins vendus (simulation basée sur le stock élevé)
      final lowSales = products
          .where((p) => (p.stockQuantity ?? 0) > 50)
          .take(5)
          .toList();

      // Ventes impayées (crédit)
      final unpaid = sales.where((s) => s.paymentType == 'credit').toList();

      // Fournisseurs avec dettes
      final debtSuppliers = suppliers
          .where((s) => (s.balance ?? 0) > 0)
          .toList();

      if (mounted) {
        setState(() {
          _lowStockProducts = lowStock;
          _lowSalesProducts = lowSales;
          _unpaidSales = unpaid;
          _suppliersWithDebt = debtSuppliers;
          _alertCount =
              lowStock.length +
              lowSales.length +
              unpaid.length +
              debtSuppliers.length;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      icon: Stack(
        children: [
          Icon(
            Icons.notifications_outlined,
            color:
                widget.iconColor ?? (isDark ? Colors.white70 : Colors.black54),
            size: 24,
          ),
          if (_alertCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$_alertCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Alertes du magasin',
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Alertes du Magasin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Produits en rupture de stock
                if (_lowStockProducts.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Produits en rupture (${_lowStockProducts.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._lowStockProducts
                      .take(3)
                      .map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 2),
                          child: Text(
                            '• ${product.name} (${product.stockQuantity} restants)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  if (_lowStockProducts.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        '... et ${_lowStockProducts.length - 3} autres',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],

                // Produits peu vendus
                if (_lowSalesProducts.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.trending_down, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Produits peu vendus (${_lowSalesProducts.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._lowSalesProducts
                      .take(3)
                      .map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 2),
                          child: Text(
                            '• ${product.name} (${product.stockQuantity} en stock)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                ],

                // Dettes clients
                if (_unpaidSales.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Créances clients (${_unpaidSales.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      'Total: ${CurrencyFormatter.formatGNF(_unpaidSales.fold<double>(0.0, (sum, sale) => sum + (sale.totalAmount ?? 0)))}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Dettes fournisseurs
                if (_suppliersWithDebt.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Dettes fournisseurs (${_suppliersWithDebt.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._suppliersWithDebt
                      .take(2)
                      .map(
                        (supplier) => Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 2),
                          child: Text(
                            '• ${supplier.name}: ${CurrencyFormatter.formatGNF(supplier.balance)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                ],

                if (_alertCount == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Aucune alerte',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      onOpened: _loadAlerts,
    );
  }
}
