import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/purchase_line.dart';
import '../models/cart_item.dart';
import '../services/purchase_cart.dart';
import '../core/database/database_helper.dart';
import '../utils/currency_formatter.dart';

class PurchaseScreen extends StatefulWidget {
  final User currentUser;

  const PurchaseScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final PurchaseCart _cart = PurchaseCart();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Supplier> _suppliers = [];
  
  String _searchQuery = '';
  String _purchaseMode = 'existing'; // 'existing' ou 'new'
  String _paymentType = 'direct'; // 'direct' ou 'debt'
  
  Supplier? _selectedSupplier;
  DateTime? _dueDate;
  double _amountPaid = 0.0;
  bool _isLoading = true;
  bool _isSaving = false;

  // Contrôleurs pour nouveau produit
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _alertThresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
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
      _showError('Erreur lors du chargement: $e');
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  void _addExistingProductToCart(Product product) {
    final quantityText = _getQuantityFromTable(product);
    final quantity = int.tryParse(quantityText) ?? 1;
    
    if (quantity > 0) {
      setState(() {
        _cart.addExistingProduct(product, quantity);
      });
      _showSuccess('Produit ajouté au panier');
    }
  }

  String _getQuantityFromTable(Product product) {
    // Cette méthode devrait récupérer la quantité saisie dans le tableau
    // Pour simplifier, on retourne "1" par défaut
    return "1";
  }

  void _addNewProductToCart() {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0.0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final alertThreshold = int.tryParse(_alertThresholdController.text);

    if (name.isEmpty || category.isEmpty || purchasePrice <= 0 || salePrice <= 0 || quantity <= 0) {
      _showError('Veuillez remplir tous les champs obligatoires');
      return;
    }

    setState(() {
      _cart.addNewProduct(
        name: name,
        category: category,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        quantity: quantity,
        alertThreshold: alertThreshold,
      );
    });

    _clearNewProductForm();
    _showSuccess('Nouveau produit ajouté au panier');
  }

  void _clearNewProductForm() {
    _nameController.clear();
    _categoryController.clear();
    _purchasePriceController.clear();
    _salePriceController.clear();
    _quantityController.clear();
    _alertThresholdController.clear();
  }

  void _updateCartItemQuantity(String itemId, int newQuantity) {
    setState(() {
      _cart.updateQuantity(itemId, newQuantity);
    });
  }

  void _removeCartItem(String itemId) {
    setState(() {
      _cart.removeItem(itemId);
    });
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

  Future<void> _validatePurchase() async {
    if (_cart.isEmpty) {
      _showError('Le panier est vide');
      return;
    }

    // OBLIGATOIRE: Fournisseur requis pour tous les achats
    if (_selectedSupplier == null) {
      _showError('Veuillez sélectionner un fournisseur. Impossible de valider un achat sans fournisseur.');
      return;
    }

    if (_paymentType == 'debt' && _dueDate == null) {
      _showError('Veuillez sélectionner une date d\'échéance pour le paiement à crédit');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Créer les nouveaux produits d'abord
      final Map<String, int> newProductIds = {};
      for (final item in _cart.items.where((item) => item.isNewProduct)) {
        final product = Product(
          name: item.name,
          category: item.category,
          purchasePrice: item.purchasePrice,
          salePrice: item.salePrice,
          stockQuantity: 0, // Sera mis à jour après
          stockAlertThreshold: item.alertThreshold,
        );
        
        final productId = await DatabaseHelper.instance.insertProduct(product);
        newProductIds[item.id] = productId;
      }

      // 2. Créer l'achat (fournisseur obligatoire)
      final purchase = Purchase(
        supplierId: _selectedSupplier!.id, // Toujours requis maintenant
        userId: widget.currentUser.id,
        totalAmount: _cart.totalAmount,
        paymentType: _paymentType,
        purchaseDate: DateTime.now().toIso8601String(),
        dueDate: _dueDate?.toIso8601String(),
        discount: _cart.discount > 0 ? _cart.discount : null,
      );

      final purchaseId = await DatabaseHelper.instance.insertPurchase(purchase);

      // 3. Créer les lignes d'achat et mettre à jour les stocks
      for (final item in _cart.items) {
        final productId = item.isNewProduct 
            ? newProductIds[item.id]!
            : item.existingProductId!;

        // Créer la ligne d'achat
        final purchaseLine = PurchaseLine(
          purchaseId: purchaseId,
          productId: productId,
          quantity: item.quantity,
          purchasePrice: item.purchasePrice,
          subtotal: item.subtotal,
        );
        await DatabaseHelper.instance.insertPurchaseLine(purchaseLine);

        // Mettre à jour le stock du produit
        final existingProduct = await DatabaseHelper.instance.getProduct(productId);
        if (existingProduct != null) {
          final updatedProduct = existingProduct.copyWith(
            stockQuantity: (existingProduct.stockQuantity ?? 0) + item.quantity,
          );
          await DatabaseHelper.instance.updateProduct(updatedProduct);
        }
      }

      // 4. Gérer la dette fournisseur si nécessaire
      if (_paymentType == 'debt' && _selectedSupplier != null) {
        final debtAmount = _cart.totalAmount - _amountPaid;
        if (debtAmount > 0) {
          final updatedSupplier = _selectedSupplier!.copyWith(
            balance: (_selectedSupplier!.balance ?? 0.0) + debtAmount,
          );
          await DatabaseHelper.instance.updateSupplier(updatedSupplier);
        }
      }

      // 5. Vider le panier et réinitialiser
      setState(() {
        _cart.clear();
        _selectedSupplier = null;
        _dueDate = null;
        _amountPaid = 0.0;
        _paymentType = 'direct';
        _purchaseMode = 'existing';
      });

      _showSuccess('Achat enregistré avec succès');
      Navigator.pop(context, true);

    } catch (e) {
      _showError('Erreur lors de l\'enregistrement: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
            onPressed: _isSaving || _cart.isEmpty ? null : _validatePurchase,
            icon: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Enregistrement...' : 'Valider l\'achat'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de mode
          _buildModeSelector(),
          
          // Contenu principal
          Expanded(
            child: Row(
              children: [
                // Zone de sélection/création de produits
                Expanded(
                  flex: 3,
                  child: _purchaseMode == 'existing' 
                      ? _buildExistingProductsView()
                      : _buildNewProductView(),
                ),
                
                // Séparateur
                Container(width: 1, color: Theme.of(context).dividerColor),
                
                // Panier et paiement
                Expanded(
                  flex: 2,
                  child: _buildCartAndPaymentView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: const Text('Produit existant'),
              subtitle: const Text('Réapprovisionnement'),
              value: 'existing',
              groupValue: _purchaseMode,
              onChanged: (value) => setState(() => _purchaseMode = value!),
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text('Nouveau produit'),
              subtitle: const Text('Création + achat'),
              value: 'new',
              groupValue: _purchaseMode,
              onChanged: (value) => setState(() => _purchaseMode = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingProductsView() {
    return Column(
      children: [
        // Header avec recherche
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Produits Disponibles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          child: ListView.builder(
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              final inCart = _cart.hasExistingProduct(product.id!);
              final cartQuantity = _cart.getExistingProductQuantity(product.id!);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text('Prix: ${product.purchasePrice?.toStringAsFixed(0)} GNF - Stock: ${product.stockQuantity ?? 0}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (inCart) ...[
                        Text('Dans panier: $cartQuantity', style: const TextStyle(color: Colors.green)),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            hintText: '1',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onSubmitted: (value) {
                            final quantity = int.tryParse(value) ?? 1;
                            if (quantity > 0) {
                              _cart.addExistingProduct(product, quantity);
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addExistingProductToCart(product),
                        child: const Text('Ajouter'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewProductView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer un Nouveau Produit',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du produit *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Catégorie *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _purchasePriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Prix d\'achat (GNF) *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _salePriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Prix de vente (GNF) *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantité *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _alertThresholdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Seuil d\'alerte (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: _addNewProductToCart,
            child: const Text('Ajouter au Panier'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartAndPaymentView() {
    return Column(
      children: [
        // Header panier
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panier d\'Achat',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Articles: ${_cart.totalQuantity}'),
                  Text(
                    'Total: ${CurrencyFormatter.formatGNF(_cart.totalAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Liste du panier
        Expanded(
          child: _cart.isEmpty
              ? const Center(child: Text('Panier vide'))
              : ListView.builder(
                  itemCount: _cart.items.length,
                  itemBuilder: (context, index) {
                    final item = _cart.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (item.isNewProduct)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'NOUVEAU',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${CurrencyFormatter.formatGNF(item.purchasePrice)}'),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _updateCartItemQuantity(item.id, item.quantity - 1),
                                      icon: const Icon(Icons.remove),
                                      iconSize: 16,
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      onPressed: () => _updateCartItemQuantity(item.id, item.quantity + 1),
                                      icon: const Icon(Icons.add),
                                      iconSize: 16,
                                    ),
                                    IconButton(
                                      onPressed: () => _removeCartItem(item.id),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      iconSize: 16,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              'Sous-total: ${CurrencyFormatter.formatGNF(item.subtotal)}',
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
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélection du fournisseur (OBLIGATOIRE pour tous les achats)
              const Text('Fournisseur *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedSupplier == null ? Colors.red : Colors.green,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: _selectSupplier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSupplier == null 
                        ? Colors.red.withOpacity(0.1) 
                        : Colors.green.withOpacity(0.1),
                    foregroundColor: _selectedSupplier == null ? Colors.red : Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_selectedSupplier == null ? Icons.warning : Icons.check_circle),
                      const SizedBox(width: 8),
                      Text(
                        _selectedSupplier?.name ?? 'SÉLECTIONNER UN FOURNISSEUR (OBLIGATOIRE)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('Mode de Paiement', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      onChanged: (value) => setState(() => _paymentType = value!),
                    ),
                  ),
                ],
              ),
              
              if (_paymentType == 'debt') ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _selectDueDate,
                  child: Text(_dueDate != null 
                      ? 'Échéance: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                      : 'Date d\'échéance'),
                ),
                const SizedBox(height: 8),
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
                if (_amountPaid < _cart.totalAmount)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Reste à payer: ${CurrencyFormatter.formatGNF(_cart.totalAmount - _amountPaid)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
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
                    _cart.setDiscount(double.tryParse(value) ?? 0.0);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Dialog pour sélectionner un fournisseur
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
        return supplier.name.toLowerCase().contains(_searchQuery.toLowerCase());
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
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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