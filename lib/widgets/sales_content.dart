import 'package:flutter/material.dart';
import '../widgets/advanced_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/sale.dart';
import '../models/sale_line.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../screens/new_sale_screen.dart';
import '../services/export_service.dart';

/// Contenu de gestion des ventes avec bouton Nouvelle Vente
class SalesContent extends StatefulWidget {
  final User currentUser;

  const SalesContent({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<SalesContent> createState() => _SalesContentState();
}

class _SalesContentState extends State<SalesContent> {
  List<Sale> _sales = [];
  List<List<String>> _salesRows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await DatabaseHelper.instance.getSales();
      // Tri automatique du plus récent au moins récent
      sales.sort((a, b) {
        if (a.saleDate == null && b.saleDate == null) return 0;
        if (a.saleDate == null) return 1;
        if (b.saleDate == null) return -1;
        return DateTime.parse(b.saleDate!).compareTo(DateTime.parse(a.saleDate!));
      });
      
      final salesRows = await _buildSalesRows(sales);
      setState(() {
        _sales = sales;
        _salesRows = salesRows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<List<String>>> _buildSalesRows(List<Sale> sales) async {
    final List<List<String>> rows = [];
    
    for (final sale in sales) {
      String clientName = 'Direct';
      String userName = 'Utilisateur inconnu';
      
      // Charger le nom du client
      if (sale.customerId != null) {
        final customer = await DatabaseHelper.instance.getCustomer(sale.customerId!);
        clientName = customer?.name ?? 'Client inconnu';
      }
      
      // Charger le nom de l'utilisateur
      if (sale.userId != null) {
        final user = await DatabaseHelper.instance.getUser(sale.userId!);
        userName = user?.fullName ?? user?.username ?? 'Utilisateur inconnu';
      }
      
      rows.add([
        sale.id.toString(),
        clientName,
        userName,
        _getPaymentTypeLabel(sale.paymentType),
        _formatDate(sale.saleDate),
        '${(sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
      ]);
    }
    
    return rows;
  }

  void _openNewSale() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewSaleScreen(currentUser: widget.currentUser),
      ),
    ).then((_) {
      // Recharger les ventes quand on revient
      _loadSales();
    });
  }

  void _editSale(int index) {
    // TODO: Implémenter l'édition de vente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Édition de vente à implémenter')),
    );
  }

  Future<void> _deleteSale(int index) async {
    try {
      await DatabaseHelper.instance.deleteSale(_sales[index].id!);
      _loadSales();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vente supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _exportSales(String format) async {
    try {
      if (format == 'pdf') {
        await ExportService.exportSalesPDF(_sales);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (format == 'excel') {
        await ExportService.exportSalesExcel(_sales);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export Excel généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Bouton Nouvelle Vente en haut
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _openNewSale,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Nouvelle Vente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                onSelected: (value) => _exportSales(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Exporter PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Exporter Excel'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Exporter', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Table des ventes
        Expanded(
          child: AdvancedDataTable(
            title: 'Historique des Ventes',
            columns: const ['ID', 'Client', 'Vendeur', 'Mode', 'Date', 'Montant total'],
            rows: _salesRows,
            onEdit: List.generate(
              _sales.length,
              (index) => () => _showSaleDetails(index),
            ),
            onDelete: List.generate(
              _sales.length,
              (index) => () => _deleteSale(index),
            ),
          ),
        ),
      ],
    );
  }

  String _getPaymentTypeLabel(String? paymentType) {
    switch (paymentType) {
      case 'direct':
        return 'Paiement direct';
      case 'client':
        return 'Vente avec client';
      case 'credit':
        return 'Dette';
      default:
        return 'Paiement direct';
    }
  }

  void _showSaleDetails(int index) {
    final sale = _sales[index];
    showDialog(
      context: context,
      builder: (context) => _SaleDetailsModal(sale: sale),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

/// Modal pour afficher les détails d'une vente
class _SaleDetailsModal extends StatefulWidget {
  final Sale sale;

  const _SaleDetailsModal({required this.sale});

  @override
  State<_SaleDetailsModal> createState() => _SaleDetailsModalState();
}

class _SaleDetailsModalState extends State<_SaleDetailsModal> {
  List<SaleLineWithProduct> _saleLines = [];
  String _customerName = '';
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaleLines();
  }

  Future<void> _loadSaleLines() async {
    try {
      final saleLines = await DatabaseHelper.instance.getSaleLines(widget.sale.id!);
      final saleLineDetails = <SaleLineWithProduct>[];
      
      // Charger le nom du client
      String customerName = 'Direct';
      if (widget.sale.customerId != null) {
        final customer = await DatabaseHelper.instance.getCustomer(widget.sale.customerId!);
        customerName = customer?.name ?? 'Client inconnu';
      }
      
      // Charger le nom de l'utilisateur
      String userName = 'Utilisateur inconnu';
      if (widget.sale.userId != null) {
        final user = await DatabaseHelper.instance.getUser(widget.sale.userId!);
        userName = user?.fullName ?? user?.username ?? 'Utilisateur inconnu';
      }
      
      for (final saleLine in saleLines) {
        final product = await DatabaseHelper.instance.getProduct(saleLine.productId!);
        if (product != null) {
          saleLineDetails.add(SaleLineWithProduct(
            saleLine: saleLine,
            product: product,
          ));
        }
      }
      
      setState(() {
        _saleLines = saleLineDetails;
        _customerName = customerName;
        _userName = userName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getPaymentTypeLabel(String? paymentType) {
    switch (paymentType) {
      case 'direct':
        return 'Paiement direct';
      case 'client':
        return 'Vente avec client';
      case 'credit':
        return 'Dette';
      default:
        return 'Paiement direct';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.receipt_long, size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Détails de la vente #${widget.sale.id}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            
            // Informations de la vente
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${_formatDate(widget.sale.saleDate)}'),
                            Text('Mode: ${_getPaymentTypeLabel(widget.sale.paymentType)}'),
                            Text('Client: $_customerName'),
                            Text('Vendeur: $_userName'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.sale.discount != null && widget.sale.discount! > 0)
                              Text('Rabais: ${widget.sale.discount!.toStringAsFixed(0)} GNF'),
                            if (widget.sale.dueDate != null)
                              Text('Date limite: ${_formatDate(widget.sale.dueDate)}'),
                            if (widget.sale.discountRate != null && widget.sale.discountRate! > 0)
                              Text('Taux remise: ${widget.sale.discountRate!.toStringAsFixed(1)}%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Titre des lignes
            Text(
              'Produits vendus',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Tableau des lignes de vente
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _saleLines.isEmpty
                      ? const Center(child: Text('Aucun produit trouvé'))
                      : SingleChildScrollView(
                          child: Table(
                            border: TableBorder.all(color: Colors.grey[300]!),
                            columnWidths: const {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(2),
                            },
                            children: [
                              // En-tête du tableau
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('Prix unitaire', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('Sous-total', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              // Lignes de données
                              ..._saleLines.map((saleLineDetail) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(saleLineDetail.product.name),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text('${saleLineDetail.saleLine.quantity}'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text('${(saleLineDetail.saleLine.salePrice ?? 0).toStringAsFixed(0)} GNF'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      '${(saleLineDetail.saleLine.subtotal ?? 0).toStringAsFixed(0)} GNF',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              )),
                            ],
                          ),
                        ),
            ),
            
            const Divider(),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(widget.sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Classe pour associer une ligne de vente avec son produit
class SaleLineWithProduct {
  final SaleLine saleLine;
  final Product product;

  SaleLineWithProduct({
    required this.saleLine,
    required this.product,
  });
}