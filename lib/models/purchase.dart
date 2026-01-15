/// Modèle pour les achats
class Purchase {
  final int? id;
  final int? supplierId;
  final int? userId;
  final String? purchaseDate;
  final double? totalAmount;
  final String? paymentType; // 'direct' ou 'debt'
  final String? dueDate;
  final double? discount;

  Purchase({
    this.id,
    this.supplierId,
    this.userId,
    this.purchaseDate,
    this.totalAmount,
    this.paymentType,
    this.dueDate,
    this.discount,
  });

  /// Convertit l'objet Purchase en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'user_id': userId,
      'purchase_date': purchaseDate,
      'total_amount': totalAmount,
      'payment_type': paymentType,
      'due_date': dueDate,
      'discount': discount,
    };
  }

  /// Crée un objet Purchase à partir d'une Map de la base de données
  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      supplierId: map['supplier_id'],
      userId: map['user_id'],
      purchaseDate: map['purchase_date'],
      totalAmount: map['total_amount']?.toDouble(),
      paymentType: map['payment_type'],
      dueDate: map['due_date'],
      discount: map['discount']?.toDouble(),
    );
  }

  /// Crée une copie de l'achat avec des modifications
  Purchase copyWith({
    int? id,
    int? supplierId,
    int? userId,
    String? purchaseDate,
    double? totalAmount,
    String? paymentType,
    String? dueDate,
    double? discount,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      userId: userId ?? this.userId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentType: paymentType ?? this.paymentType,
      dueDate: dueDate ?? this.dueDate,
      discount: discount ?? this.discount,
    );
  }
}