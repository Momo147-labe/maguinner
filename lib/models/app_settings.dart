/// Modèle pour les paramètres de l'application
class AppSettings {
  final int? id;
  final bool firstLaunchDone;
  final String? createdAt;
  final String? updatedAt;

  AppSettings({
    this.id,
    required this.firstLaunchDone,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_launch_done': firstLaunchDone ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      firstLaunchDone: (map['first_launch_done'] ?? 0) == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  AppSettings copyWith({
    int? id,
    bool? firstLaunchDone,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      firstLaunchDone: firstLaunchDone ?? this.firstLaunchDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}