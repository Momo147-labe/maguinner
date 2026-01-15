import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/purchase_line.dart';
import '../core/database/database_helper.dart';
import '../services/invoice_service.dart';
import '../utils/responsive_helper.dart';

/// Classe pour représenter un produit dans le panier
class PurchaseItem {
  final Product product;
  final int quantity;

  PurchaseItem({required this.product, required this.quantity});

  double get subtotal => (product.purchasePrice ?? 0) * quantity;

  PurchaseItem copyWith({Product? product, int? quantity}) {
    return PurchaseItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Écran pour créer un nouvel achat
class NewPurchaseScreen extends StatefulWidget {
  final User currentUser;

  const NewPurchaseScreen({Key? key, required this.currentUser})
    : super(key: key);

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
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

  // Contrôleurs pour nouveau produit
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _alertThresholdController = TextEditingController();

  // Contrôleurs pour nouveau fournisseur
  final _supplierNameController = TextEditingController();
  final _supplierPhoneController = TextEditingController();
  final _supplierAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _alertThresholdController.dispose();
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    _supplierAddressController.dispose();
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
    return _selectedProducts.values.fold(
          0.0,
          (sum, item) => sum + item.subtotal,
        ) -
        _discount;
  }

  int get _totalItems {
    return _selectedProducts.values.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _showSupplierSelectionOrCreateModal() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => _SupplierSelectionDialog(suppliers: _suppliers),
    );

    if (result == 'create_new') {
      await _createNewSupplier();
    } else if (result is Supplier) {
      setState(() {
        _selectedSupplier = result;
      });
      // Continuer avec la sauvegarde
      await _performSave();
    }
  }

  Future<void> _performSave() async {
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

      // Créer les lignes d'achat et mettre à jour les stocks
      for (final item in _selectedProducts.values) {
        final purchaseLine = PurchaseLine(
          purchaseId: purchaseId,
          productId: item.product.id ?? 0,
          quantity: item.quantity,
          purchasePrice: item.product.purchasePrice ?? 0,
          subtotal: item.subtotal,
        );
        await DatabaseHelper.instance.insertPurchaseLine(purchaseLine);

        // Mettre à jour le stock du produit
        final updatedProduct = item.product.copyWith(
          stockQuantity: (item.product.stockQuantity ?? 0) + item.quantity,
        );
        await DatabaseHelper.instance.updateProduct(updatedProduct);
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
          SnackBar(
            content: const Text('Achat enregistré avec succès'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Bon PDF',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  final newPurchase = Purchase(
                    id: purchaseId,
                    supplierId: _selectedSupplier?.id,
                    userId: widget.currentUser.id,
                    totalAmount: _totalAmount,
                    paymentType: _paymentType,
                    purchaseDate: DateTime.now().toIso8601String(),
                    dueDate: _dueDate?.toIso8601String(),
                    discount: _discount > 0 ? _discount : null,
                  );
                  await InvoiceService.generatePurchaseInvoice(newPurchase);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur génération PDF: $e')),
                  );
                }
              },
            ),
          ),
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

  Future<void> _createNewSupplier() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Fournisseur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nom et téléphone requis')),
                );
                return;
              }

              try {
                final supplier = Supplier(
                  name: name,
                  phone: phone,
                  address: address.isEmpty ? null : address,
                );
                final id = await DatabaseHelper.instance.insertSupplier(
                  supplier,
                );
                final newSupplier = supplier.copyWith(id: id);

                setState(() {
                  _suppliers.add(newSupplier);
                  _selectedSupplier = newSupplier;
                });

                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fournisseur créé avec succès')),
                );

                // Continuer avec la sauvegarde si on vient du processus d'achat
                if (_paymentType == 'debt') {
                  await _performSave();
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectSupplier() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => _SupplierSelectionDialog(suppliers: _suppliers),
    );

    if (result == 'create_new') {
      await _createNewSupplier();
    } else if (result is Supplier) {
      setState(() {
        _selectedSupplier = result;
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
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un produit'),
        ),
      );
      return;
    }

    if (_paymentType == 'debt' && _selectedSupplier == null) {
      await _showSupplierSelectionOrCreateModal();
      return;
    }

    await _performSave();
  }

  Future<void> _createNewProduct() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final alertThreshold = int.tryParse(_alertThresholdController.text);

    if (name.isEmpty ||
        category.isEmpty ||
        purchasePrice <= 0 ||
        salePrice <= 0 ||
        quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    try {
      // Créer le nouveau produit
      final product = Product(
        name: name,
        category: category,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        stockQuantity: 0, // Sera mis à jour lors de l'achat
        stockAlertThreshold: alertThreshold,
      );

      final productId = await DatabaseHelper.instance.insertProduct(product);
      final newProduct = product.copyWith(id: productId);

      // Ajouter au panier
      _addProduct(newProduct, quantity);

      // Vider le formulaire
      _nameController.clear();
      _categoryController.clear();
      _purchasePriceController.clear();
      _salePriceController.clear();
      _quantityController.clear();
      _alertThresholdController.clear();

      // Recharger la liste des produits
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nouveau produit créé et ajouté au panier'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de la création: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel Achat'),
        actions: [
          TextButton.icon(
            onPressed: _selectedProducts.isNotEmpty ? _savePurchase : null,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Valider Achat',
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Tableau des produits disponibles avec onglets
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.inventory), text: 'Produits'),
                    Tab(icon: Icon(Icons.add_box), text: 'Nouveau Produit'),
                    Tab(
                      icon: Icon(Icons.person_add),
                      text: 'Nouveau Fournisseur',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductsList(),
                    _buildNewProductForm(),
                    _buildNewSupplierForm(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Séparateur vertical
        Container(width: 1, color: Theme.of(context).dividerColor),

        // Tableau des produits sélectionnés
        Expanded(flex: 2, child: _buildSelectedProducts()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final mobileTabController = TabController(length: 3, vsync: this);
    return Column(
      children: [
        // Onglets pour basculer entre produits et panier
        Container(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: TabBar(
            controller: mobileTabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.inventory),
                text: 'Produits (${_filteredProducts.length})',
              ),
              Tab(icon: const Icon(Icons.add_box), text: 'Nouveau'),
              Tab(
                icon: const Icon(Icons.shopping_cart),
                text: 'Sélectionnés (${_selectedProducts.length})',
              ),
            ],
          ),
        ),

        // Contenu des onglets
        Expanded(
          child: TabBarView(
            controller: mobileTabController,
            children: [
              _buildProductsList(),
              _buildNewProductForm(),
              _buildSelectedProducts(),
            ],
          ),
        ),

        // Barre de résumé fixe en bas
        if (_selectedProducts.isNotEmpty) _buildMobileBottomBar(),
      ],
    );
  }

  Widget _buildMobileBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode de paiement
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mode:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _paymentType,
                    underline: const SizedBox(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'direct', child: Text('Direct')),
                      DropdownMenuItem(value: 'debt', child: Text('Dette')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _paymentType = value!;
                        if (value == 'direct') {
                          _selectedSupplier = null;
                          _dueDate = null;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_paymentType == 'debt') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectSupplier,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedSupplier != null
                            ? Colors.green
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        _selectedSupplier?.name ?? 'Fournisseur',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectDueDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dueDate != null
                            ? Colors.green
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}'
                            : 'Échéance',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Total et bouton
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${_totalAmount.toStringAsFixed(0)} GNF',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                      Text(
                        '${_selectedProducts.length} produit(s)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _savePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('VALIDER'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
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
                  _filterProducts();
                },
              ),
            ],
          ),
        ),

        // Liste des produits
        Expanded(
          child: isMobile
              ? _buildMobileProductsList()
              : _buildDesktopProductsTable(),
        ),
      ],
    );
  }

  Widget _buildMobileProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final quantityController = TextEditingController();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prix: ${(product.purchasePrice ?? 0).toStringAsFixed(0)} GNF',
                    ),
                    Text('Stock: ${product.stockQuantity ?? 0}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Quantité',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final quantity =
                            int.tryParse(quantityController.text) ?? 0;
                        if (quantity > 0) {
                          _addProduct(product, quantity);
                          quantityController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ajouter'),
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

  Widget _buildDesktopProductsTable() {
    return SingleChildScrollView(
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
                  child: Text(product.name, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                Text('${(product.purchasePrice ?? 0).toStringAsFixed(0)} GNF'),
              ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
    );
  }

  Widget _buildSelectedProducts() {
    final isMobile = ResponsiveHelper.isMobile(context);

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
                'Produits Sélectionnés',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              ? const Center(child: Text('Aucun produit sélectionné'))
              : ListView.builder(
                  itemCount: _selectedProducts.length,
                  itemBuilder: (context, index) {
                    final item = _selectedProducts.values.elementAt(index);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(item.product.purchasePrice ?? 0).toStringAsFixed(0)} GNF',
                                ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Section paiement (desktop seulement)
        if (!isMobile) _buildPaymentSection(),
      ],
    );
  }

  Widget _buildNewProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer un Nouveau Produit',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              labelText: 'Quantité à acheter *',
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
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createNewProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Créer et Ajouter au Panier',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewSupplierForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer un Nouveau Fournisseur',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _supplierNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du fournisseur *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _supplierPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _supplierAddressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Adresse (optionnel)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createNewSupplierFromForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Créer le Fournisseur',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewSupplierFromForm() async {
    final name = _supplierNameController.text.trim();
    final phone = _supplierPhoneController.text.trim();
    final address = _supplierAddressController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et téléphone sont requis')),
      );
      return;
    }

    try {
      final supplier = Supplier(
        name: name,
        phone: phone,
        address: address.isEmpty ? null : address,
      );

      final id = await DatabaseHelper.instance.insertSupplier(supplier);
      final newSupplier = supplier.copyWith(id: id);

      setState(() {
        _suppliers.add(newSupplier);
        _selectedSupplier = newSupplier;
      });

      // Vider le formulaire
      _supplierNameController.clear();
      _supplierPhoneController.clear();
      _supplierAddressController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fournisseur créé avec succès')),
      );

      // Continuer avec la sauvegarde si on vient du processus d'achat
      if (_paymentType == 'debt') {
        await _performSave();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de la création: $e')));
    }
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
              child: Text(
                _selectedSupplier?.name ?? 'Sélectionner un fournisseur',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selectDueDate,
              child: Text(
                _dueDate != null
                    ? 'Échéance: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                    : 'Sélectionner une date d\'échéance',
              ),
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
    );
  }
}

/// Dialog pour sélectionner un fournisseur
class _SupplierSelectionDialog extends StatefulWidget {
  final List<Supplier> suppliers;

  const _SupplierSelectionDialog({required this.suppliers});

  @override
  State<_SupplierSelectionDialog> createState() =>
      _SupplierSelectionDialogState();
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'create_new'),
                icon: const Icon(Icons.add),
                label: const Text('Nouveau Fournisseur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredSuppliers.isEmpty
                  ? const Center(child: Text('Aucun fournisseur trouvé'))
                  : ListView.builder(
                      itemCount: _filteredSuppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = _filteredSuppliers[index];
                        return ListTile(
                          title: Text(supplier.name),
                          subtitle: Text(supplier.phone ?? ''),
                          trailing: Text(
                            'Solde: ${(supplier.balance ?? 0).toStringAsFixed(0)} GNF',
                            style: TextStyle(
                              color: (supplier.balance ?? 0) > 0
                                  ? Colors.red
                                  : Colors.green,
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
