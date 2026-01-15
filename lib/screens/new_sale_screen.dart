import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/sale_line.dart';
import '../services/invoice_service.dart';
import '../utils/responsive_helper.dart';

/// Page de nouvelle vente avec modes de paiement avancés
class NewSaleScreen extends StatefulWidget {
  final User currentUser;

  const NewSaleScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];
  Map<int, CartItem> _cart = {};
  bool _isLoading = true;
  Map<String, double> _salesSummary = {};
  
  final TextEditingController _searchController = TextEditingController();
  String _paymentType = 'direct';
  Customer? _selectedCustomer;
  double _discount = 0;
  DateTime? _dueDate;
  double _discountRate = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await DatabaseHelper.instance.getProducts();
      final customers = await DatabaseHelper.instance.getCustomers();
      final salesSummary = await _calculateSalesSummary();
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _customers = customers;
        _salesSummary = salesSummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) =>
        product.name.toLowerCase().contains(query) ||
        (product.barcode?.toLowerCase().contains(query) ?? false) ||
        (product.category?.toLowerCase().contains(query) ?? false)
      ).toList();
    });
  }

  Future<Map<String, double>> _calculateSalesSummary() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));
    
    final sales = await DatabaseHelper.instance.getSales();
    
    double todayTotal = 0;
    double yesterdayTotal = 0;
    double dayBeforeTotal = 0;
    
    for (final sale in sales) {
      if (sale.saleDate != null) {
        final saleDate = DateTime.parse(sale.saleDate!);
        final saleDateOnly = DateTime(saleDate.year, saleDate.month, saleDate.day);
        
        if (saleDateOnly == today) {
          todayTotal += sale.totalAmount ?? 0;
        } else if (saleDateOnly == yesterday) {
          yesterdayTotal += sale.totalAmount ?? 0;
        } else if (saleDateOnly == dayBeforeYesterday) {
          dayBeforeTotal += sale.totalAmount ?? 0;
        }
      }
    }
    
    return {
      'today': todayTotal,
      'yesterday': yesterdayTotal,
      'dayBefore': dayBeforeTotal,
    };
  }

  void _addToCart(Product product) {
    if (product.id == null) return;
    if (product.stockQuantity == null || product.stockQuantity! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit en rupture de stock')),
      );
      return;
    }

    final productId = product.id!;
    setState(() {
      if (_cart.containsKey(productId)) {
        final currentQuantity = _cart[productId]!.quantity;
        if (currentQuantity < product.stockQuantity!) {
          _cart[productId] = _cart[productId]!.copyWith(
            quantity: currentQuantity + 1,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock insuffisant')),
          );
        }
      } else {
        _cart[productId] = CartItem(
          product: product,
          quantity: 1,
        );
      }
    });
  }

  void _increaseQuantity(int productId) {
    final item = _cart[productId];
    if (item != null && item.quantity < item.product.stockQuantity!) {
      setState(() {
        _cart[productId] = item.copyWith(quantity: item.quantity + 1);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock insuffisant')),
      );
    }
  }

  void _decreaseQuantity(int productId) {
    final item = _cart[productId];
    if (item != null) {
      if (item.quantity > 1) {
        setState(() {
          _cart[productId] = item.copyWith(quantity: item.quantity - 1);
        });
      } else {
        setState(() {
          _cart.remove(productId);
        });
      }
    }
  }

  double get _cartSubtotal {
    return _cart.values.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get _cartTotal {
    return _cartSubtotal - _discount;
  }

  Future<void> _showClientSelectionOrCreateModal() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => _ClientSelectionModal(
        customers: _customers,
        onClientSelected: (customer) {
          Navigator.pop(context, customer);
        },
        onCreateNew: () {
          Navigator.pop(context, 'create_new');
        },
      ),
    );
    
    if (result == 'create_new') {
      await _createNewCustomer();
    } else if (result is Customer) {
      setState(() => _selectedCustomer = result);
      
      if (_paymentType == 'client') {
        _showDiscountModal();
      } else if (_paymentType == 'credit') {
        _showCreditModal();
      }
    }
  }

  Future<void> _createNewCustomer() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Client'),
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
                final customer = Customer(
                  name: name,
                  phone: phone,
                  address: address.isEmpty ? null : address,
                );
                final id = await DatabaseHelper.instance.insertCustomer(customer);
                final newCustomer = customer.copyWith(id: id);
                
                setState(() {
                  _customers.add(newCustomer);
                  _selectedCustomer = newCustomer;
                });

                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client créé avec succès')),
                );
                
                // Continuer avec le processus de vente
                if (_paymentType == 'client') {
                  _showDiscountModal();
                } else if (_paymentType == 'credit') {
                  _showCreditModal();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showDiscountModal() {
    final discountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rabais optionnel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Client: ${_selectedCustomer?.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: 'Montant du rabais (GNF)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _discount = 0);
              Navigator.pop(context);
            },
            child: const Text('Pas de rabais'),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(discountController.text) ?? 0;
              setState(() => _discount = discount);
              Navigator.pop(context);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _showCreditModal() {
    final discountRateController = TextEditingController();
    DateTime? selectedDate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Vente à crédit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Client: ${_selectedCustomer?.name}'),
              const SizedBox(height: 16),
              ListTile(
                title: Text(selectedDate == null 
                  ? 'Sélectionner la date de remboursement'
                  : 'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setModalState(() => selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discountRateController,
                decoration: const InputDecoration(
                  labelText: 'Taux de remise (%) - optionnel',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedDate == null ? null : () {
                final rate = double.tryParse(discountRateController.text) ?? 0;
                setState(() {
                  _dueDate = selectedDate;
                  _discountRate = rate;
                });
                Navigator.pop(context);
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le panier est vide')),
      );
      return;
    }

    if ((_paymentType == 'client' || _paymentType == 'credit') && _selectedCustomer == null) {
      await _showClientSelectionOrCreateModal();
      return;
    }

    try {
      final sale = Sale(
        customerId: _selectedCustomer?.id,
        userId: widget.currentUser.id, // Association automatique à l'utilisateur connecté
        saleDate: DateTime.now().toIso8601String(),
        totalAmount: _cartTotal,
        paymentType: _paymentType,
        discount: _discount > 0 ? _discount : null,
        dueDate: _dueDate?.toIso8601String(),
        discountRate: _discountRate > 0 ? _discountRate : null,
      );
      
      final saleId = await DatabaseHelper.instance.insertSale(sale);
      
      for (final item in _cart.values) {
        final saleLine = SaleLine(
          saleId: saleId,
          productId: item.product.id!,
          quantity: item.quantity,
          salePrice: item.product.salePrice ?? 0,
          subtotal: item.subtotal,
        );
        
        await DatabaseHelper.instance.insertSaleLine(saleLine);
        
        final updatedProduct = item.product.copyWith(
          stockQuantity: (item.product.stockQuantity ?? 0) - item.quantity,
        );
        await DatabaseHelper.instance.updateProduct(updatedProduct);
      }
      
      // Ajouter au solde client si vente à crédit
      if (_paymentType == 'credit' && _selectedCustomer != null) {
        // Note: Ici on pourrait ajouter une table dettes ou utiliser un champ dans customer
        // Pour l'instant, on utilise le calcul dynamique dans clients_content.dart
      }
      
      setState(() {
        _cart.clear();
        _paymentType = 'direct';
        _selectedCustomer = null;
        _discount = 0;
        _dueDate = null;
        _discountRate = 0;
      });
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vente enregistrée avec succès (${_cartTotal.toStringAsFixed(0)} GNF)'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Facture PDF',
            textColor: Colors.white,
            onPressed: () async {
              try {
                final newSale = Sale(
                  id: saleId,
                  customerId: _selectedCustomer?.id,
                  userId: widget.currentUser.id,
                  saleDate: DateTime.now().toIso8601String(),
                  totalAmount: _cartTotal,
                  paymentType: _paymentType,
                  discount: _discount > 0 ? _discount : null,
                  dueDate: _dueDate?.toIso8601String(),
                  discountRate: _discountRate > 0 ? _discountRate : null,
                );
                await InvoiceService.generateSaleInvoice(newSale);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur génération PDF: $e')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Vente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // COLONNE GAUCHE - LISTE DES PRODUITS
        Expanded(
          flex: 3,
          child: _buildProductsList(),
        ),
        
        // COLONNE DROITE - PANIER
        Expanded(
          flex: 2,
          child: _buildCart(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Onglets pour basculer entre produits et panier
        Container(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.inventory),
                text: 'Produits (${_filteredProducts.length})',
              ),
              Tab(
                icon: const Icon(Icons.shopping_cart),
                text: 'Panier (${_cart.length})',
              ),
            ],
          ),
        ),
        
        // Contenu des onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductsList(),
              _buildCart(),
            ],
          ),
        ),
        
        // Barre de résumé fixe en bas
        if (_cart.isNotEmpty) _buildMobileBottomBar(),
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
            // Mode de vente
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
                      DropdownMenuItem(value: 'client', child: Text('Client')),
                      DropdownMenuItem(value: 'credit', child: Text('Crédit')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _paymentType = value!;
                        _selectedCustomer = null;
                        _discount = 0;
                        _dueDate = null;
                        _discountRate = 0;
                      });
                    },
                  ),
                ],
              ),
            ),
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
                        'Total: ${_cartTotal.toStringAsFixed(0)} GNF',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${_cart.length} article(s)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _completeSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // En-tête avec recherche
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory),
                    const SizedBox(width: 8),
                    Text(
                      'Produits Disponibles',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un produit...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // Liste des produits
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                final isOutOfStock = (product.stockQuantity ?? 0) <= 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOutOfStock 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.primary,
                      child: Text(
                        product.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: TextStyle(
                        color: isOutOfStock ? Colors.grey : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prix: ${(product.salePrice ?? 0).toStringAsFixed(0)} GNF',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Stock: ${product.stockQuantity ?? 0}',
                          style: TextStyle(
                            color: isOutOfStock ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: isOutOfStock ? null : () => _addToCart(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 36),
                      ),
                      child: const Text('Ajouter'),
                    ),
                    onTap: isOutOfStock ? null : () => _addToCart(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // En-tête avec résumé des ventes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text(
                      'Panier (${_cart.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // RÉSUMÉ DES VENTES (mobile et desktop)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Résumé des Ventes',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Aujourd\'hui:'),
                          Text(
                            '${(_salesSummary['today'] ?? 0).toStringAsFixed(0)} GNF',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hier:'),
                          Text(
                            '${(_salesSummary['yesterday'] ?? 0).toStringAsFixed(0)} GNF',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu du panier
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'Panier vide\nCliquez sur un produit pour l\'ajouter',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart.values.elementAt(index);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('Prix unitaire: ${(item.product.salePrice ?? 0).toStringAsFixed(0)} GNF'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _decreaseQuantity(item.product.id!),
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _increaseQuantity(item.product.id!),
                                        icon: const Icon(Icons.add_circle, color: Colors.green),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${item.subtotal.toStringAsFixed(0)} GNF',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Section paiement et total (desktop seulement)
          if (!isMobile) _buildPaymentSection(),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Type de paiement
          DropdownButtonFormField<String>(
            value: _paymentType,
            decoration: const InputDecoration(
              labelText: 'Type de paiement',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'direct', child: Text('Paiement direct')),
              DropdownMenuItem(value: 'client', child: Text('Vente avec client')),
              DropdownMenuItem(value: 'credit', child: Text('Vente à crédit')),
            ],
            onChanged: (value) {
              setState(() {
                _paymentType = value!;
                _selectedCustomer = null;
                _discount = 0;
                _dueDate = null;
                _discountRate = 0;
              });
            },
          ),
          
          // Informations client et conditions
          if (_selectedCustomer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client: ${_selectedCustomer!.name}', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_discount > 0)
                    Text('Rabais: ${_discount.toStringAsFixed(0)} GNF'),
                  if (_dueDate != null)
                    Text('Date limite: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                  if (_discountRate > 0)
                    Text('Taux de remise: ${_discountRate.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Calculs
          if (_discount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sous-total:'),
                Text('${_cartSubtotal.toStringAsFixed(0)} GNF'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rabais:'),
                Text('- ${_discount.toStringAsFixed(0)} GNF', 
                  style: const TextStyle(color: Colors.red)),
              ],
            ),
            const Divider(),
          ],
          
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
                '${_cartTotal.toStringAsFixed(0)} GNF',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _cart.isEmpty ? null : () {
                    setState(() {
                      _cart.clear();
                      _paymentType = 'direct';
                      _selectedCustomer = null;
                      _discount = 0;
                      _dueDate = null;
                      _discountRate = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Vider'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _cart.isEmpty ? null : _completeSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'VALIDER VENTE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal de sélection de client
class _ClientSelectionModal extends StatefulWidget {
  final List<Customer> customers;
  final Function(Customer) onClientSelected;
  final VoidCallback onCreateNew;

  const _ClientSelectionModal({
    required this.customers,
    required this.onClientSelected,
    required this.onCreateNew,
  });

  @override
  State<_ClientSelectionModal> createState() => _ClientSelectionModalState();
}

class _ClientSelectionModalState extends State<_ClientSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
    _searchController.addListener(_filterCustomers);
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = widget.customers.where((customer) =>
        customer.name.toLowerCase().contains(query) ||
        (customer.phone?.toLowerCase().contains(query) ?? false)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Sélectionner un client',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onCreateNew,
                icon: const Icon(Icons.person_add),
                label: const Text('Nouveau Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? const Center(child: Text('Aucun client trouvé'))
                  : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(customer.name[0].toUpperCase()),
                            ),
                            title: Text(customer.name),
                            subtitle: Text(customer.phone ?? 'Pas de téléphone'),
                            onTap: () => widget.onClientSelected(customer),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Classe pour gérer les éléments du panier
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => (product.salePrice ?? 0) * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}