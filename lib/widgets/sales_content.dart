import 'package:flutter/material.dart';
import '../widgets/advanced_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/sale.dart';
import '../models/sale_line.dart';
import '../models/product.dart';
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
        return DateTime.parse(
          b.saleDate!,
        ).compareTo(DateTime.parse(a.saleDate!));
      });

      final salesRows = await _buildSalesRows(sales);
      setState(() {
        _sales = sales;
        _salesRows = salesRows;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<List<String>>> _buildSalesRows(List<Sale> sales) async {
    final List<List<String>> rows = [];

    for (final sale in sales) {
      String clientName = 'Direct';
      String userName = 'Utilisateur inconnu';

      // Charger le nom du client
      if (sale.customerId != null) {
        final customer = await DatabaseHelper.instance.getCustomer(
          sale.customerId!,
        );
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
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                NewSaleScreen(currentUser: widget.currentUser),
          ),
        )
        .then((_) {
          // Recharger les ventes quand on revient
          _loadSales();
        });
  }

  Future<void> _deleteSale(int index) async {
    try {
      if (_sales[index].id != null) {
        await DatabaseHelper.instance.deleteSale(_sales[index].id!);
        _loadSales();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vente supprimée avec succès'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _exportSales(String format) async {
    try {
      if (format == 'pdf') {
        await ExportService.exportSalesPDF(_sales);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Export PDF généré avec succès'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (format == 'excel') {
        await ExportService.exportSalesExcel(_sales);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Export Excel généré avec succès'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export: $e')));
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
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openNewSale,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Nouvelle Vente', style: TextStyle(fontSize: 14)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: PopupMenuButton<String>(
                  onSelected: (value) => _exportSales(value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text('Exporter PDF', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excel',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart_rounded, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          const Text('Exporter Excel', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Exporter',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
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
            columns: const [
              'ID',
              'Client',
              'Vendeur',
              'Mode',
              'Date',
              'Montant total',
            ],
            rows: _salesRows,
            onEdit: List.generate(
              _sales.length,
              (index) =>
                  () => _showSaleDetails(index),
            ),
            onDelete: List.generate(
              _sales.length,
              (index) =>
                  () => _deleteSale(index),
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
    if (widget.sale.id == null) return;

    try {
      final saleLines = await DatabaseHelper.instance.getSaleLines(
        widget.sale.id!,
      );
      final saleLineDetails = <SaleLineWithProduct>[];

      // Charger le nom du client
      String customerName = 'Direct';
      if (widget.sale.customerId != null) {
        final customer = await DatabaseHelper.instance.getCustomer(
          widget.sale.customerId!,
        );
        customerName = customer?.name ?? 'Client inconnu';
      }

      // Charger le nom de l'utilisateur
      String userName = 'Utilisateur inconnu';
      if (widget.sale.userId != null) {
        final user = await DatabaseHelper.instance.getUser(widget.sale.userId!);
        userName = user?.fullName ?? user?.username ?? 'Utilisateur inconnu';
      }

      for (final saleLine in saleLines) {
        final product = await DatabaseHelper.instance.getProduct(
          saleLine.productId,
        );
        if (product != null) {
          saleLineDetails.add(
            SaleLineWithProduct(saleLine: saleLine, product: product),
          );
        }
      }

      if (mounted) {
        setState(() {
          _saleLines = saleLineDetails;
          _customerName = customerName;
          _userName = userName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth > 700 ? 600 : screenWidth * 0.9).toDouble();
    
    return Dialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Vente #${widget.sale.id}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(28, 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Informations de la vente
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildInfoItem(
                          'Date',
                          _formatDate(widget.sale.saleDate),
                          Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _buildInfoItem(
                          'Client',
                          _customerName,
                          Icons.person_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildInfoItem(
                          'Mode de paiement',
                          _getPaymentTypeLabel(widget.sale.paymentType),
                          Icons.payment_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _buildInfoItem(
                          'Vendeur',
                          _userName,
                          Icons.badge_rounded,
                        ),
                      ),
                    ],
                  ),
                  if ((widget.sale.discount != null &&
                          widget.sale.discount! > 0) ||
                      widget.sale.dueDate != null) ...[
                    const Divider(height: 32),
                    Row(
                      children: [
                        if (widget.sale.discount != null &&
                            widget.sale.discount! > 0)
                          Expanded(
                            flex: 1,
                            child: _buildInfoItem(
                              'Rabais',
                              '${widget.sale.discount!.toStringAsFixed(0)} GNF',
                              Icons.discount_rounded,
                              valueColor: Colors.orange,
                            ),
                          ),
                        if (widget.sale.discount != null &&
                            widget.sale.discount! > 0 &&
                            widget.sale.dueDate != null)
                          const SizedBox(width: 8),
                        if (widget.sale.dueDate != null)
                          Expanded(
                            flex: 1,
                            child: _buildInfoItem(
                              'Échéance',
                              _formatDate(widget.sale.dueDate),
                              Icons.event_rounded,
                              valueColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Produits vendus',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Liste des produits
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _saleLines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aucun produit trouvé',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: _saleLines.length,
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Divider(
                            height: 1,
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final line = _saleLines[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        line.product.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${line.saleLine.quantity} × ${(line.saleLine.salePrice).toStringAsFixed(0)} GNF',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(line.saleLine.subtotal).toStringAsFixed(0)} GNF',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'TOTAL À PAYER',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      '${(widget.sale.totalAmount ?? 0).toStringAsFixed(0)} GNF',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Classe pour associer une ligne de vente avec son produit
class SaleLineWithProduct {
  final SaleLine saleLine;
  final Product product;

  SaleLineWithProduct({required this.saleLine, required this.product});
}
