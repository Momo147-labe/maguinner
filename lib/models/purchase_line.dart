/// Modèle pour les lignes d'achat
class PurchaseLine {
  final int? id;
  final int purchaseId;
  final int productId;
  final int quantity;
  final double purchasePrice;
  final double subtotal;

  PurchaseLine({
    this.id,
    required this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.purchasePrice,
    required this.subtotal,
  });

  /// Convertit l'objet PurchaseLine en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'subtotal': subtotal,
    };
  }

  /// Crée un objet PurchaseLine à partir d'une Map de la base de données
  factory PurchaseLine.fromMap(Map<String, dynamic> map) {
    return PurchaseLine(
      id: map['id'],
      purchaseId: map['purchase_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      purchasePrice: map['purchase_price'].toDouble(),
      subtotal: map['subtotal'].toDouble(),
    );
  }

  /// Crée une copie de la ligne d'achat avec des modifications
  PurchaseLine copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    int? quantity,
    double? purchasePrice,
    double? subtotal,
  }) {
    return PurchaseLine(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}