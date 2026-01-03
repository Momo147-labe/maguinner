/// Modèle pour les éléments du panier d'achat (temporaire, en mémoire uniquement)
class CartItem {
  final String id; // ID temporaire unique
  final String name;
  final String category;
  final double purchasePrice;
  final double salePrice;
  final int quantity;
  final int? alertThreshold;
  final bool isNewProduct; // true si c'est un nouveau produit, false si existant
  final int? existingProductId; // ID du produit existant si applicable

  CartItem({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.quantity,
    this.alertThreshold,
    required this.isNewProduct,
    this.existingProductId,
  });

  double get subtotal => purchasePrice * quantity;

  CartItem copyWith({
    String? id,
    String? name,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    int? alertThreshold,
    bool? isNewProduct,
    int? existingProductId,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isNewProduct: isNewProduct ?? this.isNewProduct,
      existingProductId: existingProductId ?? this.existingProductId,
    );
  }
}