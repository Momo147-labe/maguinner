/// Modèle pour les ventes
class Sale {
  final int? id;
  final int? customerId;
  final int? userId; // ID de l'utilisateur qui a effectué la vente
  final String? saleDate;
  final double? totalAmount;
  final String? paymentType; // 'direct', 'client', 'credit'
  final double? discount; // rabais optionnel
  final String? dueDate; // date de remboursement pour crédit
  final double? discountRate; // taux de remise pour crédit

  Sale({
    this.id,
    this.customerId,
    this.userId,
    this.saleDate,
    this.totalAmount,
    this.paymentType,
    this.discount,
    this.dueDate,
    this.discountRate,
  });

  /// Convertit l'objet Sale en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'user_id': userId,
      'sale_date': saleDate,
      'total_amount': totalAmount,
      'payment_type': paymentType,
      'discount': discount,
      'due_date': dueDate,
      'discount_rate': discountRate,
    };
  }

  /// Crée un objet Sale à partir d'une Map de la base de données
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      customerId: map['customer_id'],
      userId: map['user_id'],
      saleDate: map['sale_date'],
      totalAmount: map['total_amount']?.toDouble(),
      paymentType: map['payment_type'],
      discount: map['discount']?.toDouble(),
      dueDate: map['due_date'],
      discountRate: map['discount_rate']?.toDouble(),
    );
  }

  /// Crée une copie de la vente avec des modifications
  Sale copyWith({
    int? id,
    int? customerId,
    int? userId,
    String? saleDate,
    double? totalAmount,
    String? paymentType,
    double? discount,
    String? dueDate,
    double? discountRate,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      saleDate: saleDate ?? this.saleDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentType: paymentType ?? this.paymentType,
      discount: discount ?? this.discount,
      dueDate: dueDate ?? this.dueDate,
      discountRate: discountRate ?? this.discountRate,
    );
  }
}