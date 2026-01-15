/// Modèle pour les utilisateurs du système
class User {
  final int? id;
  final String username;
  final String password;
  final String? fullName;
  final String? role;
  final String? createdAt;
  final String? secretCode;

  User({
    this.id,
    required this.username,
    required this.password,
    this.fullName,
    this.role,
    this.createdAt,
    this.secretCode,
  });

  /// Convertit l'objet User en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt,
      'secret_code': secretCode,
    };
  }

  /// Crée un objet User à partir d'une Map de la base de données
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      fullName: map['full_name'],
      role: map['role'],
      createdAt: map['created_at'],
      secretCode: map['secret_code'],
    );
  }

  /// Crée une copie de l'utilisateur avec des modifications
  User copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    String? createdAt,
    String? secretCode,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      secretCode: secretCode ?? this.secretCode,
    );
  }
}