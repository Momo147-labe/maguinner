import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/purchase_line.dart';
import '../core/database/database_helper.dart';

/// Écran pour créer un nouvel achat
class NewPurchaseScreen extends StatefulWidget {
  final User currentUser;

  const NewPurchaseScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Map<int, PurchaseItem> _selectedProducts = {};
  List<Supplier> _suppliers = [];
  String _searchQuery = '';
  String _paymentType = 'direct';
  Supplier? _selectedSupplier;
  DateTime? _dueDate;
  double _discount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await DatabaseHelper.instance.getProducts();
      final suppliers = await DatabaseHelper.instance.getSuppliers();
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _suppliers = suppliers;
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

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final searchLower = _searchQuery.toLowerCase();
        return product.name.toLowerCase().contains(searchLower);
      }).toList();
    });
  }

  void _addProduct(Product product, int quantity) {
    if (quantity <= 0) return;
    
    setState(() {
      _selectedProducts[product.id!] = PurchaseItem(
        product: product,
        quantity: quantity,
      );
    });
  }

  void _updateQuantity(int productId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _selectedProducts.remove(productId);
      } else {
        final item = _selectedProducts[productId];
        if (item != null) {
          _selectedProducts[productId] = item.copyWith(quantity: newQuantity);
        }
      }
    });
  }

  double get _totalAmount {
    return _selectedProducts.values.fold(0.0, (sum, item) => sum + item.subtotal) - _discount;
  }

  int get _totalItems {
    return _selectedProducts.values.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _selectSupplier() async {
    final supplier = await showDialog<Supplier>(
      context: context,
      builder: (context) => _SupplierSelectionDialog(suppliers: _suppliers),
    );
    
    if (supplier != null) {
      setState(() {
        _selectedSupplier = supplier;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _savePurchase() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un produit')),
      );
      return;
    }

    if (_paymentType == 'debt' && _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fournisseur pour le paiement à crédit')),
      );
      return;
    }

    try {
      // Créer l'achat
      final purchase = Purchase(
        supplierId: _selectedSupplier?.id,
        userId: widget.currentUser.id,
        totalAmount: _totalAmount,
        paymentType: _paymentType,
        purchaseDate: DateTime.now().toIso8601String(),
        dueDate: _dueDate?.toIso8601String(),
        discount: _discount > 0 ? _discount : null,
      );

      final purchaseId = await DatabaseHelper.instance.insertPurchase(purchase);

      // Créer les lignes d'achat
      for (final item in _selectedProducts.values) {
        final purchaseLine = PurchaseLine(
          purchaseId: purchaseId,
          productId: item.product.id??0,
          quantity: item.quantity,
          purchasePrice: item.product.purchasePrice ?? 0,
          subtotal: item.subtotal,
        );
        await DatabaseHelper.instance.insertPurchaseLine(purchaseLine);
      }

      // Mettre à jour le solde du fournisseur si paiement à crédit
      if (_paymentType == 'debt' && _selectedSupplier != null) {
        final updatedSupplier = _selectedSupplier!.copyWith(
          balance: (_selectedSupplier!.balance ?? 0) + _totalAmount,
        );
        await DatabaseHelper.instance.updateSupplier(updatedSupplier);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat enregistré avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel Achat'),
        actions: [
          TextButton.icon(
            onPressed: _selectedProducts.isNotEmpty ? _savePurchase : null,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Valider Achat', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Tableau des produits disponibles
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Header produits
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produits Disponibles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterProducts();
                        },
                      ),
                    ],
                  ),
                ),
                
                // Liste des produits
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Produit')),
                        DataColumn(label: Text('Prix d\'achat')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Quantité')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: _filteredProducts.map((product) {
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text('${(product.purchasePrice ?? 0).toStringAsFixed(0)} GNF')),
                            DataCell(Text('${product.stockQuantity ?? 0}')),
                            DataCell(
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  onSubmitted: (value) {
                                    final quantity = int.tryParse(value) ?? 0;
                                    if (quantity > 0) {
                                      _addProduct(product, quantity);
                                    }
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  // Récupérer la quantité du TextField
                                  _addProduct(product, 1);
                                },
                                child: const Text('Ajouter'),
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
          
          // Séparateur vertical
          Container(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
          
          // Tableau des produits sélectionnés
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Header panier
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produits Sélectionnés',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Articles: $_totalItems'),
                          Text(
                            'Total: ${_totalAmount.toStringAsFixed(0)} GNF',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Liste des produits sélectionnés
                Expanded(
                  child: _selectedProducts.isEmpty
                      ? const Center(
                          child: Text('Aucun produit sélectionné'),
                        )
                      : ListView.builder(
                          itemCount: _selectedProducts.length,
                          itemBuilder: (context, index) {
                            final item = _selectedProducts.values.elementAt(index);
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${(item.product.purchasePrice ?? 0).toStringAsFixed(0)} GNF'),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () => _updateQuantity(
                                                item.product.id!,
                                                item.quantity - 1,
                                              ),
                                              icon: const Icon(Icons.remove),
                                              iconSize: 16,
                                            ),
                                            Text('${item.quantity}'),
                                            IconButton(
                                              onPressed: () => _updateQuantity(
                                                item.product.id!,
                                                item.quantity + 1,
                                              ),
                                              icon: const Icon(Icons.add),
                                              iconSize: 16,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sous-total: ${item.subtotal.toStringAsFixed(0)} GNF',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Section paiement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode de Paiement',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Direct'),
                              value: 'direct',
                              groupValue: _paymentType,
                              onChanged: (value) {
                                setState(() {
                                  _paymentType = value!;
                                  _selectedSupplier = null;
                                  _dueDate = null;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Dette'),
                              value: 'debt',
                              groupValue: _paymentType,
                              onChanged: (value) {
                                setState(() => _paymentType = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      if (_paymentType == 'debt') ...[
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _selectSupplier,
                          child: Text(_selectedSupplier?.name ?? 'Sélectionner un fournisseur'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _selectDueDate,
                          child: Text(_dueDate != null 
                              ? 'Échéance: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                              : 'Sélectionner une date d\'échéance'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Remise (GNF)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _discount = double.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ],
                    ],
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

/// Classe pour représenter un produit dans le panier
class PurchaseItem {
  final Product product;
  final int quantity;

  PurchaseItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => (product.purchasePrice ?? 0) * quantity;

  PurchaseItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return PurchaseItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Dialog pour sélectionner un fournisseur
class _SupplierSelectionDialog extends StatefulWidget {
  final List<Supplier> suppliers;

  const _SupplierSelectionDialog({required this.suppliers});

  @override
  State<_SupplierSelectionDialog> createState() => _SupplierSelectionDialogState();
}

class _SupplierSelectionDialogState extends State<_SupplierSelectionDialog> {
  List<Supplier> _filteredSuppliers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredSuppliers = widget.suppliers;
  }

  void _filterSuppliers() {
    setState(() {
      _filteredSuppliers = widget.suppliers.where((supplier) {
        final searchLower = _searchQuery.toLowerCase();
        return supplier.name.toLowerCase().contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner un Fournisseur'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un fournisseur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterSuppliers();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSuppliers.length,
                itemBuilder: (context, index) {
                  final supplier = _filteredSuppliers[index];
                  return ListTile(
                    title: Text(supplier.name),
                    subtitle: Text(supplier.phone ?? ''),
                    trailing: Text(
                      'Solde: ${(supplier.balance ?? 0).toStringAsFixed(0)} GNF',
                      style: TextStyle(
                        color: (supplier.balance ?? 0) > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, supplier),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}