class Team {
  final String id;
  final String name;
  final String? slug;
  final String? avatar;
  final String? description;
  final DateTime createdAt;
  final String? membership;
  final String? role;

  Team({
    required this.id,
    required this.name,
    this.slug,
    this.avatar,
    this.description,
    required this.createdAt,
    this.membership,
    this.role,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      membership: json['membership']?['id'] as String?,
      role: json['membership']?['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'avatar': avatar,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
