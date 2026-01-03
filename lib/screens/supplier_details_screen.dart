import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/purchase_line.dart';
import '../core/database/database_helper.dart';
import '../utils/currency_formatter.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierDetailsScreen({Key? key, required this.supplier}) : super(key: key);

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  List<Purchase> _purchases = [];
  Map<int, List<PurchaseLine>> _purchaseLines = {};
  Map<int, String> _productNames = {};
  bool _isLoading = true;
  
  double _totalPurchases = 0;
  double _totalDebt = 0;
  double _totalPaid = 0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadSupplierData();
  }

  Future<void> _loadSupplierData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les achats du fournisseur
      final allPurchases = await DatabaseHelper.instance.getPurchases();
      final supplierPurchases = allPurchases.where((purchase) => purchase.supplierId == widget.supplier.id).toList();
      
      // Charger les lignes d'achat et noms des produits
      final Map<int, List<PurchaseLine>> purchaseLines = {};
      final Map<int, String> productNames = {};
      
      for (final purchase in supplierPurchases) {
        final lines = await DatabaseHelper.instance.getPurchaseLines(purchase.id!);
        purchaseLines[purchase.id!] = lines;
        
        for (final line in lines) {
          if (!productNames.containsKey(line.productId)) {
            final product = await DatabaseHelper.instance.getProduct(line.productId);
            productNames[line.productId] = product?.name ?? 'Produit inconnu';
          }
        }
      }
      
      // Calculer les totaux
      double totalPurchases = 0;
      double totalDebt = 0;
      double totalPaid = 0;
      
      for (final purchase in supplierPurchases) {
        totalPurchases += purchase.totalAmount ?? 0;
        if (purchase.paymentType == 'debt') {
          totalDebt += purchase.totalAmount ?? 0;
        } else {
          totalPaid += purchase.totalAmount ?? 0;
        }
      }
      
      setState(() {
        _purchases = supplierPurchases;
        _purchaseLines = purchaseLines;
        _productNames = productNames;
        _totalPurchases = totalPurchases;
        _totalDebt = totalDebt;
        _totalPaid = totalPaid;
        _totalTransactions = supplierPurchases.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails - ${widget.supplier.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSupplierInfo(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildTransactionsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSupplierInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.blue.shade600, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Informations Fournisseur',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nom', widget.supplier.name),
            _buildInfoRow('Téléphone', widget.supplier.phone ?? 'Non renseigné'),
            _buildInfoRow('Email', widget.supplier.email ?? 'Non renseigné'),
            _buildInfoRow('Adresse', widget.supplier.address ?? 'Non renseignée'),
            _buildInfoRow('Solde actuel', CurrencyFormatter.formatGNF(widget.supplier.balance ?? 0)),
            _buildInfoRow('Date création', _formatDate(widget.supplier.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Achats',
                CurrencyFormatter.formatGNF(_totalPurchases),
                Icons.shopping_bag,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Dettes',
                CurrencyFormatter.formatGNF(_totalDebt),
                Icons.account_balance_wallet,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Payé',
                CurrencyFormatter.formatGNF(_totalPaid),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Transactions',
                _totalTransactions.toString(),
                Icons.receipt,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.purple.shade600, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Historique des Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_purchases.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune action enregistrée',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _purchases.length,
                itemBuilder: (context, index) {
                  final purchase = _purchases[index];
                  return _buildTransactionCard(purchase);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Purchase purchase) {
    final purchaseLines = _purchaseLines[purchase.id!] ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: purchase.paymentType == 'debt' ? Colors.red : Colors.green,
          child: Icon(
            purchase.paymentType == 'debt' ? Icons.schedule : Icons.check_circle,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Achat #${purchase.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(purchase.purchaseDate)}'),
            Text('Montant: ${CurrencyFormatter.formatGNF(purchase.totalAmount ?? 0)}'),
            Text('Type: ${purchase.paymentType == 'debt' ? 'À crédit' : 'Payé'}'),
            if (purchase.dueDate != null)
              Text('Échéance: ${_formatDate(purchase.dueDate)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Produits achetés:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...purchaseLines.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(_productNames[line.productId] ?? 'Produit inconnu'),
                      ),
                      Text('${line.quantity} × ${CurrencyFormatter.formatGNF(line.purchasePrice ?? 0)}'),
                      const SizedBox(width: 16),
                      Text(
                        CurrencyFormatter.formatGNF(line.subtotal ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Non défini';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}