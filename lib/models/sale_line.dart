/// Modèle pour les lignes de vente
class SaleLine {
  final int? id;
  final int saleId;
  final int productId;
  final int quantity;
  final double salePrice;
  final double subtotal;

  SaleLine({
    this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.salePrice,
    required this.subtotal,
  });

  /// Convertit l'objet SaleLine en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'sale_price': salePrice,
      'subtotal': subtotal,
    };
  }

  /// Crée un objet SaleLine à partir d'une Map de la base de données
  factory SaleLine.fromMap(Map<String, dynamic> map) {
    return SaleLine(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      salePrice: map['sale_price'].toDouble(),
      subtotal: map['subtotal'].toDouble(),
    );
  }

  /// Crée une copie de la ligne de vente avec des modifications
  SaleLine copyWith({
    int? id,
    int? saleId,
    int? productId,
    int? quantity,
    double? salePrice,
    double? subtotal,
  }) {
    return SaleLine(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice ?? this.salePrice,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}