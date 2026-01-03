class Product {
  int? id;
  String name;
  String? barcode;
  String? category;
  double? purchasePrice;
  double? salePrice;
  int stockQuantity;
  int stockAlertThreshold;
  String? imagePath;

  Product({
    this.id,
    required this.name,
    this.barcode,
    this.category,
    this.purchasePrice,
    this.salePrice,
    required this.stockQuantity,
    required this.stockAlertThreshold,
    this.imagePath,
  });

  // Convertir en Map pour SQLite
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

  // Créer à partir d'un Map SQLite
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      category: map['category'],
      purchasePrice: map['purchase_price'],
      salePrice: map['sale_price'],
      stockQuantity: map['stock_quantity'],
      stockAlertThreshold: map['stock_alert_threshold'],
      imagePath: map['image_path'],
    );
  }
}
