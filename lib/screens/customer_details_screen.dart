import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/sale_line.dart';
import '../core/database/database_helper.dart';
import '../utils/currency_formatter.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({Key? key, required this.customer}) : super(key: key);

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  List<Sale> _sales = [];
  Map<int, List<SaleLine>> _saleLines = {};
  Map<int, String> _productNames = {};
  bool _isLoading = true;
  
  double _totalSales = 0;
  double _totalDebt = 0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les ventes du client
      final allSales = await DatabaseHelper.instance.getSales();
      final customerSales = allSales.where((sale) => sale.customerId == widget.customer.id).toList();
      
      // Charger les lignes de vente et noms des produits
      final Map<int, List<SaleLine>> saleLines = {};
      final Map<int, String> productNames = {};
      
      for (final sale in customerSales) {
        final lines = await DatabaseHelper.instance.getSaleLines(sale.id!);
        saleLines[sale.id!] = lines;
        
        for (final line in lines) {
          if (!productNames.containsKey(line.productId)) {
            final product = await DatabaseHelper.instance.getProduct(line.productId);
            productNames[line.productId] = product?.name ?? 'Produit inconnu';
          }
        }
      }
      
      // Calculer les totaux
      double totalSales = 0;
      double totalDebt = 0;
      
      for (final sale in customerSales) {
        totalSales += sale.totalAmount ?? 0;
        if (sale.paymentType == 'debt') {
          totalDebt += sale.totalAmount ?? 0;
        }
      }
      
      setState(() {
        _sales = customerSales;
        _saleLines = saleLines;
        _productNames = productNames;
        _totalSales = totalSales;
        _totalDebt = totalDebt;
        _totalTransactions = customerSales.length;
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
        title: Text('Détails - ${widget.customer.name}'),
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
                  _buildCustomerInfo(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildTransactionsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade600, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Informations Client',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nom', widget.customer.name),
            _buildInfoRow('Téléphone', widget.customer.phone ?? 'Non renseigné'),
            _buildInfoRow('Email', widget.customer.email ?? 'Non renseigné'),
            _buildInfoRow('Adresse', widget.customer.address ?? 'Non renseignée'),
            _buildInfoRow('Date création', _formatDate(widget.customer.createdAt)),
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
                'Total Ventes',
                CurrencyFormatter.formatGNF(_totalSales),
                Icons.shopping_cart,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Dettes',
                CurrencyFormatter.formatGNF(_totalDebt),
                Icons.account_balance_wallet,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Transactions',
                _totalTransactions.toString(),
                Icons.receipt,
                Colors.blue,
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
            if (_sales.isEmpty)
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
                itemCount: _sales.length,
                itemBuilder: (context, index) {
                  final sale = _sales[index];
                  return _buildTransactionCard(sale);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Sale sale) {
    final saleLines = _saleLines[sale.id!] ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: sale.paymentType == 'debt' ? Colors.orange : Colors.green,
          child: Icon(
            sale.paymentType == 'debt' ? Icons.schedule : Icons.check_circle,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Vente #${sale.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(sale.saleDate)}'),
            Text('Montant: ${CurrencyFormatter.formatGNF(sale.totalAmount ?? 0)}'),
            Text('Type: ${sale.paymentType == 'debt' ? 'À crédit' : 'Payé'}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Produits vendus:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...saleLines.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(_productNames[line.productId] ?? 'Produit inconnu'),
                      ),
                      Text('${line.quantity} × ${CurrencyFormatter.formatGNF(line.salePrice ?? 0)}'),
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