/// Modèle pour les clients
class Customer {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? createdAt;

  Customer({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.createdAt,
  });

  /// Convertit l'objet Customer en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'created_at': createdAt,
    };
  }

  /// Crée un objet Customer à partir d'une Map de la base de données
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      createdAt: map['created_at'],
    );
  }

  /// Crée une copie du client avec des modifications
  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}