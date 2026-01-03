import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/purchase_line.dart';
import '../core/database/database_helper.dart';

/// Écran pour créer un nouvel achat avec gestion produits existants/nouveaux
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
  String _purchaseMode = 'existing'; // 'existing' ou 'new'
  Supplier? _selectedSupplier;
  DateTime? _dueDate;
  double _discount = 0.0;
  double _amountPaid = 0.0;
  bool _isLoading = true;

  // Nouveaux champs pour créer un produit
  final _newProductNameController = TextEditingController();
  final _newProductCategoryController = TextEditingController();
  final _newProductPurchasePriceController = TextEditingController();
  final _newProductSalePriceController = TextEditingController();
  final _newProductQuantityController = TextEditingController();
  final _newProductAlertThresholdController = TextEditingController();

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
    if (quantity <= 0 || product.id == null) return;
    
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
    if (_purchaseMode == 'new') {
      final quantity = int.tryParse(_newProductQuantityController.text) ?? 0;
      final price = double.tryParse(_newProductPurchasePriceController.text) ?? 0.0;
      return (price * quantity) - _discount;
    }
    return _selectedProducts.values.fold(0.0, (sum, item) => sum + item.subtotal) - _discount;
  }

  int get _totalItems {
    if (_purchaseMode == 'new') {
      return int.tryParse(_newProductQuantityController.text) ?? 0;
    }
    return _selectedProducts.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _remainingDebt {
    return _totalAmount - _amountPaid;
  }

  Future<void> _addNewProduct() async {
    final name = _newProductNameController.text.trim();
    final category = _newProductCategoryController.text.trim();
    final purchasePrice = double.tryParse(_newProductPurchasePriceController.text) ?? 0.0;
    final salePrice = double.tryParse(_newProductSalePriceController.text) ?? 0.0;
    final quantity = int.tryParse(_newProductQuantityController.text) ?? 0;
    final alertThreshold = int.tryParse(_newProductAlertThresholdController.text);

    if (name.isEmpty || category.isEmpty || purchasePrice <= 0 || salePrice <= 0 || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    final newProduct = Product(
      name: name,
      category: category,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      stockQuantity: quantity,
      stockAlertThreshold: alertThreshold,
    );

    try {
      final productId = await DatabaseHelper.instance.insertProduct(newProduct);
      final productWithId = newProduct.copyWith(id: productId);
      
      setState(() {
        _products.add(productWithId);
        _filteredProducts = _products;
        _selectedProducts[productId] = PurchaseItem(
          product: productWithId,
          quantity: quantity,
        );
        _purchaseMode = 'existing';
      });
      
      // Clear form
      _newProductNameController.clear();
      _newProductCategoryController.clear();
      _newProductPurchasePriceController.clear();
      _newProductSalePriceController.clear();
      _newProductQuantityController.clear();
      _newProductAlertThresholdController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau produit ajouté avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du produit: $e')),
      );
    }
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
    if (_purchaseMode == 'existing' && _selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un produit')),
      );
      return;
    }

    if (_purchaseMode == 'new') {
      final name = _newProductNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez créer le nouveau produit d\'abord')),
        );
        return;
      }
      await _addNewProduct();
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
      
      for (final item in _selectedProducts.values) {
        if (item.product.id == null) continue;
        
        // Mettre à jour le stock du produit
        final updatedProduct = item.product.copyWith(
          stockQuantity: (item.product.stockQuantity ?? 0) + item.quantity,
        );
        await DatabaseHelper.instance.updateProduct(updatedProduct);
        
        final purchaseLine = PurchaseLine(
          purchaseId: purchaseId,
          productId: item.product.id!,
          quantity: item.quantity,
          purchasePrice: item.product.purchasePrice ?? 0.0,
          subtotal: item.subtotal,
        );
        await DatabaseHelper.instance.insertPurchaseLine(purchaseLine);
      }

      // Mettre à jour le solde du fournisseur si paiement à crédit
      if (_paymentType == 'debt' && _selectedSupplier != null) {
        final debtAmount = _remainingDebt;
        if (debtAmount > 0) {
          final updatedSupplier = _selectedSupplier!.copyWith(
            balance: (_selectedSupplier!.balance ?? 0.0) + debtAmount,
          );
          await DatabaseHelper.instance.updateSupplier(updatedSupplier);
        }
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

  Widget _buildExistingProductView() {
    return Row(
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
        
        // Panier et paiement
        Expanded(
          flex: 2,
          child: _buildCartAndPayment(),
        ),
      ],
    );
  }

  Widget _buildNewProductView() {
    return Row(
      children: [
        // Formulaire nouveau produit
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer un Nouveau Produit',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _newProductNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du produit *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newProductCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newProductPurchasePriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix d\'achat (GNF) *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newProductSalePriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix de vente (GNF) *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newProductQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantité initiale *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newProductAlertThresholdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Seuil d\'alerte (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addNewProduct,
                  child: const Text('Créer et Ajouter au Panier'),
                ),
              ],
            ),
          ),
        ),
        
        // Séparateur vertical
        Container(
          width: 1,
          color: Theme.of(context).dividerColor,
        ),
        
        // Résumé et paiement
        Expanded(
          flex: 2,
          child: _buildCartAndPayment(),
        ),
      ],
    );
  }

  Widget _buildCartAndPayment() {
    return Column(
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
                _purchaseMode == 'new' ? 'Nouveau Produit' : 'Produits Sélectionnés',
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
          child: _selectedProducts.isEmpty && _purchaseMode == 'existing'
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
                          _amountPaid = 0.0;
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
                    labelText: 'Montant payé (GNF)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _amountPaid = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Reste à payer: ${_remainingDebt.toStringAsFixed(0)} GNF',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
              
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Remise (GNF)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _discount = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
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
            onPressed: (_selectedProducts.isNotEmpty || _purchaseMode == 'new') ? _savePurchase : null,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de mode d'achat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Produit existant'),
                    subtitle: const Text('Réapprovisionnement'),
                    value: 'existing',
                    groupValue: _purchaseMode,
                    onChanged: (value) {
                      setState(() {
                        _purchaseMode = value!;
                        _selectedProducts.clear();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Nouveau produit'),
                    subtitle: const Text('Création + achat'),
                    value: 'new',
                    groupValue: _purchaseMode,
                    onChanged: (value) {
                      setState(() {
                        _purchaseMode = value!;
                        _selectedProducts.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: _purchaseMode == 'existing' 
                ? _buildExistingProductView()
                : _buildNewProductView(),
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

  double get subtotal => (product.purchasePrice ?? 0.0) * quantity;

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