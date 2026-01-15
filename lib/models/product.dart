/// Modèle pour les produits
class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String? category;
  final double? purchasePrice;
  final double? salePrice;
  final int? stockQuantity;
  final int? stockAlertThreshold;
  final String? imagePath;

  Product({
    this.id,
    required this.name,
    this.barcode,
    this.category,
    this.purchasePrice,
    this.salePrice,
    this.stockQuantity,
    this.stockAlertThreshold,
    this.imagePath,
  });

  /// Convertit l'objet Product en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock_quantity': stockQuantity,
      'stock_alert_threshold': stockAlertThreshold,
      'image_path': imagePath,
    };
  }

  /// Crée un objet Product à partir d'une Map de la base de données
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      category: map['category'],
      purchasePrice: map['purchase_price']?.toDouble(),
      salePrice: map['sale_price']?.toDouble(),
      stockQuantity: map['stock_quantity'],
      stockAlertThreshold: map['stock_alert_threshold'],
      imagePath: map['image_path'],
    );
  }

  /// Crée une copie du produit avec des modifications
  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? stockQuantity,
    int? stockAlertThreshold,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockAlertThreshold: stockAlertThreshold ?? this.stockAlertThreshold,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// Vérifie si le stock est en alerte
  bool get isLowStock {
    if (stockQuantity == null || stockAlertThreshold == null) return false;
    return stockQuantity! <= stockAlertThreshold!;
  }
}