import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/custom_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/product.dart';

/// Écran de gestion des produits
class ProductsScreen extends StatefulWidget {
  final User currentUser;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ProductsScreen({
    Key? key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await DatabaseHelper.instance.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _onNavigate(String route) {
    if (route == '/login') {
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      Navigator.of(context).pushNamed(route, arguments: widget.currentUser);
    }
  }

  void _showProductDialog([Product? product]) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        product: product,
        onSave: (savedProduct) async {
          try {
            if (product == null) {
              await DatabaseHelper.instance.insertProduct(savedProduct);
            } else {
              await DatabaseHelper.instance.updateProduct(savedProduct);
            }
            _loadProducts();
            Navigator.of(context).pop();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteProduct(int index) async {
    try {
      await DatabaseHelper.instance.deleteProduct(_products[index].id!);
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentRoute: '/products',
            onNavigate: _onNavigate,
          ),
          Expanded(
            child: Column(
              children: [
                Header(
                  userName: widget.currentUser.fullName ?? widget.currentUser.username,
                  isDarkMode: widget.isDarkMode,
                  onThemeToggle: widget.onThemeToggle,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomDataTable(
                          title: 'Gestion des Produits',
                          columns: const [
                            'ID',
                            'Nom',
                            'Code-barres',
                            'Catégorie',
                            'Prix d\'achat',
                            'Prix de vente',
                            'Stock',
                            'Seuil d\'alerte',
                          ],
                          rows: _products.map((product) => [
                            product.id.toString(),
                            product.name,
                            product.barcode ?? '',
                            product.category ?? '',
                            '${product.purchasePrice?.toStringAsFixed(2) ?? '0'} €',
                            '${product.salePrice?.toStringAsFixed(2) ?? '0'} €',
                            product.stockQuantity?.toString() ?? '0',
                            product.stockAlertThreshold?.toString() ?? '0',
                          ]).toList(),
                          onAdd: () => _showProductDialog(),
                          onEdit: List.generate(
                            _products.length,
                            (index) => () => _showProductDialog(_products[index]),
                          ),
                          onDelete: List.generate(
                            _products.length,
                            (index) => () => _deleteProduct(index),
                          ),
                        ),
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

/// Dialog pour ajouter/modifier un produit
class ProductDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductDialog({
    Key? key,
    this.product,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _alertController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _purchasePriceController = TextEditingController(
      text: widget.product?.purchasePrice?.toString() ?? '',
    );
    _salePriceController = TextEditingController(
      text: widget.product?.salePrice?.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQuantity?.toString() ?? '',
    );
    _alertController = TextEditingController(
      text: widget.product?.stockAlertThreshold?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _alertController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        category: _categoryController.text.isEmpty ? null : _categoryController.text,
        purchasePrice: double.tryParse(_purchasePriceController.text),
        salePrice: double.tryParse(_salePriceController.text),
        stockQuantity: int.tryParse(_stockController.text),
        stockAlertThreshold: int.tryParse(_alertController.text),
      );
      widget.onSave(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Ajouter un produit' : 'Modifier le produit'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Code-barres'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(labelText: 'Prix d\'achat'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceController,
                      decoration: const InputDecoration(labelText: 'Prix de vente'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _alertController,
                      decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}