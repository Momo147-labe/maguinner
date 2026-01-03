import '../models/cart_item.dart';
import '../models/product.dart';

/// Gestionnaire du panier d'achat (état local uniquement)
class PurchaseCart {
  final Map<String, CartItem> _items = {};
  double _discount = 0.0;

  // Getters
  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  
  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotalAmount => _items.values.fold(0.0, (sum, item) => sum + item.subtotal);
  
  double get totalAmount => subtotalAmount - _discount;
  
  double get discount => _discount;

  // Ajouter un produit existant au panier
  void addExistingProduct(Product product, int quantity) {
    if (quantity <= 0 || product.id == null) return;
    
    final itemId = 'existing_${product.id}';
    
    if (_items.containsKey(itemId)) {
      // Augmenter la quantité si déjà dans le panier
      final existingItem = _items[itemId]!;
      _items[itemId] = existingItem.copyWith(quantity: existingItem.quantity + quantity);
    } else {
      // Ajouter nouveau item
      _items[itemId] = CartItem(
        id: itemId,
        name: product.name,
        category: product.category ?? '',
        purchasePrice: product.purchasePrice ?? 0.0,
        salePrice: product.salePrice ?? 0.0,
        quantity: quantity,
        alertThreshold: product.stockAlertThreshold,
        isNewProduct: false,
        existingProductId: product.id,
      );
    }
  }

  // Ajouter un nouveau produit au panier
  void addNewProduct({
    required String name,
    required String category,
    required double purchasePrice,
    required double salePrice,
    required int quantity,
    int? alertThreshold,
  }) {
    if (quantity <= 0 || name.trim().isEmpty) return;
    
    final itemId = 'new_${DateTime.now().millisecondsSinceEpoch}';
    
    _items[itemId] = CartItem(
      id: itemId,
      name: name.trim(),
      category: category.trim(),
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      quantity: quantity,
      alertThreshold: alertThreshold,
      isNewProduct: true,
      existingProductId: null,
    );
  }

  // Mettre à jour la quantité d'un item
  void updateQuantity(String itemId, int newQuantity) {
    if (!_items.containsKey(itemId)) return;
    
    if (newQuantity <= 0) {
      _items.remove(itemId);
    } else {
      _items[itemId] = _items[itemId]!.copyWith(quantity: newQuantity);
    }
  }

  // Supprimer un item du panier
  void removeItem(String itemId) {
    _items.remove(itemId);
  }

  // Définir la remise
  void setDiscount(double discount) {
    _discount = discount >= 0 ? discount : 0.0;
  }

  // Vider le panier
  void clear() {
    _items.clear();
    _discount = 0.0;
  }

  // Vérifier si un produit existant est déjà dans le panier
  bool hasExistingProduct(int productId) {
    return _items.containsKey('existing_$productId');
  }

  // Obtenir la quantité d'un produit existant dans le panier
  int getExistingProductQuantity(int productId) {
    final item = _items['existing_$productId'];
    return item?.quantity ?? 0;
  }
}