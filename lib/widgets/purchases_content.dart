import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/purchase.dart';
import '../core/database/database_helper.dart';
import '../screens/new_purchase_screen.dart';
import '../utils/currency_formatter.dart';

/// Widget principal pour la gestion des achats
class PurchasesContent extends StatefulWidget {
  final User currentUser;

  const PurchasesContent({Key? key, required this.currentUser})
    : super(key: key);

  @override
  State<PurchasesContent> createState() => _PurchasesContentState();
}

class _PurchasesContentState extends State<PurchasesContent> {
  List<Purchase> _purchases = [];
  List<Purchase> _filteredPurchases = [];
  Map<int, String> _supplierNames = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortColumn = 'purchase_date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      final purchases = await DatabaseHelper.instance.getPurchases();
      final suppliers = await DatabaseHelper.instance.getSuppliers();

      // Créer un map des noms de fournisseurs
      final supplierMap = <int, String>{};
      for (final supplier in suppliers) {
        supplierMap[supplier.id!] = supplier.name;
      }

      // Trier par date décroissante (plus récents en premier)
      purchases.sort((a, b) {
        if (a.purchaseDate == null && b.purchaseDate == null) return 0;
        if (a.purchaseDate == null) return 1;
        if (b.purchaseDate == null) return -1;
        return DateTime.parse(
          b.purchaseDate!,
        ).compareTo(DateTime.parse(a.purchaseDate!));
      });

      setState(() {
        _purchases = purchases;
        _supplierNames = supplierMap;
        _filteredPurchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _filterPurchases() {
    setState(() {
      _filteredPurchases = _purchases.where((purchase) {
        final supplierName = _supplierNames[purchase.supplierId] ?? '';
        final searchLower = _searchQuery.toLowerCase();

        return purchase.id.toString().contains(searchLower) ||
            supplierName.toLowerCase().contains(searchLower) ||
            (purchase.totalAmount?.toString().contains(searchLower) ?? false);
      }).toList();

      _sortPurchases();
    });
  }

  void _sortPurchases() {
    _filteredPurchases.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortColumn) {
        case 'id':
          aValue = a.id ?? 0;
          bValue = b.id ?? 0;
          break;
        case 'supplier':
          aValue = _supplierNames[a.supplierId] ?? '';
          bValue = _supplierNames[b.supplierId] ?? '';
          break;
        case 'purchase_date':
          aValue = a.purchaseDate ?? '';
          bValue = b.purchaseDate ?? '';
          break;
        case 'total_amount':
          aValue = a.totalAmount ?? 0;
          bValue = b.totalAmount ?? 0;
          break;
        default:
          return 0;
      }

      final result = aValue.compareTo(bValue);
      return _sortAscending ? result : -result;
    });
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _sortPurchases();
    });
  }

  Future<void> _deletePurchase(Purchase purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              const Text('Confirmer la suppression'),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'achat #${purchase.id} ?\nCette action est irréversible.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_rounded),
              label: const Text('Supprimer'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deletePurchase(purchase.id!);
        _loadPurchases();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Achat supprimé avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  void _showPurchaseDetails(Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: theme.cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icons.receipt_long_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de l\'achat #${purchase.id}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(purchase.purchaseDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Fournisseur',
                        _supplierNames[purchase.supplierId] ?? 'Inconnu',
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Total',
                        CurrencyFormatter.formatGNF(purchase.totalAmount ?? 0),
                        isBold: true,
                        color: Colors.green,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Mode de paiement',
                        purchase.paymentType == 'debt' ? 'Dette' : 'Direct',
                      ),
                      if (purchase.dueDate != null) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Date d\'échéance',
                          _formatDate(purchase.dueDate),
                        ),
                      ],
                      if (purchase.discount != null &&
                          purchase.discount! > 0) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Remise',
                          CurrencyFormatter.formatGNF(purchase.discount!),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des Achats',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Utilisateur: ${widget.currentUser.fullName ?? widget.currentUser.username}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NewPurchaseScreen(currentUser: widget.currentUser),
                      ),
                    );
                    if (result == true) {
                      _loadPurchases();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvel Achat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Rechercher par numéro, fournisseur ou montant...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterPurchases();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _loadPurchases,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
          ),

          // Tableau des achats avec design professionnel
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPurchases.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun achat trouvé',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header du tableau
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Liste des Achats (${_filteredPurchases.length})',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Contenu du tableau
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildProfessionalDataTable(),
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

  Widget _buildProfessionalDataTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _getSortColumnIndex(),
          sortAscending: _sortAscending,
          headingRowColor: MaterialStateProperty.all(
            isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          ),
          dataRowColor: MaterialStateProperty.resolveWith<Color?>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.hovered)) {
              return isDark ? Colors.grey.shade700 : Colors.blue.shade50;
            }
            return null;
          }),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 12,
          ),
          dataTextStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 12,
          ),
          columnSpacing: 16,
          horizontalMargin: 8,
          columns: [
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tag,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  const Text('N°', style: TextStyle(fontSize: 12)),
                ],
              ),
              onSort: (columnIndex, ascending) => _onSort('id'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  const Text('Fournisseur', style: TextStyle(fontSize: 12)),
                ],
              ),
              onSort: (columnIndex, ascending) => _onSort('supplier'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  const Text('Date', style: TextStyle(fontSize: 12)),
                ],
              ),
              onSort: (columnIndex, ascending) => _onSort('purchase_date'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  const Text('Total', style: TextStyle(fontSize: 12)),
                ],
              ),
              onSort: (columnIndex, ascending) => _onSort('total_amount'),
              numeric: true,
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payment,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  const Text('Paiement', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            DataColumn(
              label: const Text('Actions', style: TextStyle(fontSize: 12)),
            ),
          ],
        rows: _filteredPurchases.asMap().entries.map((entry) {
          final index = entry.key;
          final purchase = entry.value;
          final isEven = index % 2 == 0;

          return DataRow(
            color: MaterialStateProperty.all(
              isEven
                  ? (isDark
                        ? Colors.grey.shade900.withOpacity(0.3)
                        : Colors.grey.shade50.withOpacity(0.5))
                  : (isDark
                        ? Colors.grey.shade800.withOpacity(0.3)
                        : Colors.white),
            ),
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${purchase.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _supplierNames[purchase.supplierId] ??
                            'Fournisseur inconnu',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  _formatDate(purchase.purchaseDate),
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              DataCell(
                Text(
                  CurrencyFormatter.formatGNF(purchase.totalAmount ?? 0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: purchase.paymentType == 'debt'
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: purchase.paymentType == 'debt'
                          ? Colors.orange
                          : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    purchase.paymentType == 'debt' ? 'Dette' : 'Direct',
                    style: TextStyle(
                      color: purchase.paymentType == 'debt'
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: () => _showPurchaseDetails(purchase),
                        icon: const Icon(Icons.visibility, size: 18),
                        color: Colors.blue,
                        tooltip: 'Voir détails',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: () => _deletePurchase(purchase),
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        tooltip: 'Supprimer',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
        ),
      ),
    );
  }

  int? _getSortColumnIndex() {
    switch (_sortColumn) {
      case 'id':
        return 0;
      case 'supplier':
        return 1;
      case 'purchase_date':
        return 2;
      case 'total_amount':
        return 3;
      default:
        return null;
    }
  }
}
