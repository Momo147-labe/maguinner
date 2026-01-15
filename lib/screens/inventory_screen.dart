import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/custom_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/product.dart';

/// Écran de gestion de l'inventaire
class InventoryScreen extends StatefulWidget {
  final User currentUser;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const InventoryScreen({
    Key? key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await DatabaseHelper.instance.getProducts();
      setState(() {
        _products = products;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentRoute: '/inventory',
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
                      : Column(
                          children: [
                            // Statistiques d'inventaire
                            Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Total Produits',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          Text(
                                            _products.length.toString(),
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Stock Faible',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          Text(
                                            _products.where((p) => p.isLowStock).length.toString(),
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Table d'inventaire
                            Expanded(
                              child: CustomDataTable(
                                title: 'État de l\'Inventaire',
                                columns: const [
                                  'Nom',
                                  'Catégorie',
                                  'Stock actuel',
                                  'Seuil d\'alerte',
                                  'Statut',
                                ],
                                rows: _products.map((product) => [
                                  product.name,
                                  product.category ?? '',
                                  product.stockQuantity?.toString() ?? '0',
                                  product.stockAlertThreshold?.toString() ?? '0',
                                  product.isLowStock ? 'ALERTE' : 'OK',
                                ]).toList(),
                              ),
                            ),
                          ],
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