import 'package:flutter/material.dart';
import '../widgets/advanced_datatable.dart';
import '../core/database/database_helper.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../utils/barcode_generator.dart';
import '../utils/currency_formatter.dart';

/// Contenu de gestion des produits avec DataTable avancée
class ProductsContent extends StatefulWidget {
  final User currentUser;

  const ProductsContent({Key? key, required this.currentUser})
    : super(key: key);

  @override
  State<ProductsContent> createState() => _ProductsContentState();
}

class _ProductsContentState extends State<ProductsContent> {
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
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
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
            } else {}
            if (!mounted) return;
            _loadProducts();
            Navigator.of(context).pop();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteProduct(int index) async {
    try {
      await DatabaseHelper.instance.deleteProduct(_products[index].id!);
      if (!mounted) return;
      _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: AdvancedDataTable(
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
              'Statut',
            ],
            rows: _products
                .map(
                  (product) => [
                    product.id.toString(),
                    product.name,
                    product.barcode ?? '',
                    product.category ?? '',
                    CurrencyFormatter.formatGNF(product.purchasePrice),
                    CurrencyFormatter.formatGNF(product.salePrice),
                    product.stockQuantity?.toString() ?? '0',
                    product.stockAlertThreshold?.toString() ?? '0',
                    product.isLowStock ? 'ALERTE' : 'OK',
                  ],
                )
                .toList(),
            onAdd: () => _showProductDialog(),
            onEdit: List.generate(
              _products.length,
              (index) =>
                  () => _showProductDialog(_products[index]),
            ),
            onDelete: List.generate(
              _products.length,
              (index) =>
                  () => _deleteProduct(index),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog pour ajouter/modifier un produit
class ProductDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductDialog({Key? key, this.product, required this.onSave})
    : super(key: key);

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
    _barcodeController = TextEditingController(
      text: widget.product?.barcode ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.product?.category ?? '',
    );
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
        barcode: _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text,
        category: _categoryController.text.isEmpty
            ? null
            : _categoryController.text,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                        widget.product == null
                            ? Icons.add_box_rounded
                            : Icons.edit_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.product == null
                          ? 'Ajouter un produit'
                          : 'Modifier le produit',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du produit *',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Code-barres',
                    prefixIcon: const Icon(Icons.qr_code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        decoration: InputDecoration(
                          labelText: 'Prix d\'achat',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceVariant.withOpacity(
                                  0.3,
                                ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _salePriceController,
                        decoration: InputDecoration(
                          labelText: 'Prix de vente',
                          prefixIcon: const Icon(Icons.sell_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceVariant.withOpacity(
                                  0.3,
                                ),
                        ),
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
                        decoration: InputDecoration(
                          labelText: 'Stock',
                          prefixIcon: const Icon(Icons.warehouse_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceVariant.withOpacity(
                                  0.3,
                                ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _alertController,
                        decoration: InputDecoration(
                          labelText: 'Seuil d\'alerte',
                          prefixIcon: const Icon(Icons.warning_amber_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceVariant.withOpacity(
                                  0.3,
                                ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Enregistrer'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
