import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/custom_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/purchase.dart';

/// Écran de gestion des achats
class PurchasesScreen extends StatefulWidget {
  final User currentUser;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const PurchasesScreen({
    Key? key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<Purchase> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      final purchases = await DatabaseHelper.instance.getPurchases();
      setState(() {
        _purchases = purchases;
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
            currentRoute: '/purchases',
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
                          title: 'Gestion des Achats',
                          columns: const [
                            'ID',
                            'Fournisseur ID',
                            'Date d\'achat',
                            'Montant total',
                          ],
                          rows: _purchases.map((purchase) => [
                            purchase.id.toString(),
                            purchase.supplierId.toString(),
                            purchase.purchaseDate ?? '',
                            '${purchase.totalAmount?.toStringAsFixed(2) ?? '0'} €',
                          ]).toList(),
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