/// Modèle pour les fournisseurs
class Supplier {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final double? balance; // Solde du fournisseur
  final String? createdAt;

  Supplier({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.balance,
    this.createdAt,
  });

  /// Convertit l'objet Supplier en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'balance': balance,
      'created_at': createdAt,
    };
  }

  /// Crée un objet Supplier à partir d'une Map de la base de données
  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      balance: map['balance']?.toDouble(),
      createdAt: map['created_at'],
    );
  }

  /// Crée une copie du fournisseur avec des modifications
  Supplier copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    double? balance,
    String? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}