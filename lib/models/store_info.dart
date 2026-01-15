/// Modèle pour les informations du magasin
class StoreInfo {
  final int? id;
  final String name;
  final String ownerName;
  final String phone;
  final String email;
  final String location;
  final String? createdAt;
  final String? updatedAt;

  StoreInfo({
    this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.location,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
      'location': location,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      id: map['id'],
      name: map['name'],
      ownerName: map['owner_name'],
      phone: map['phone'],
      email: map['email'],
      location: map['location'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  StoreInfo copyWith({
    int? id,
    String? name,
    String? ownerName,
    String? phone,
    String? email,
    String? location,
    String? createdAt,
    String? updatedAt,
  }) {
    return StoreInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}