class User {
  final String id;
  final String email;
  final String? username;
  final String? name;
  final String? avatar;
  final DateTime createdAt;
  final Map<String, dynamic>? platform;

  User({
    required this.id,
    required this.email,
    this.username,
    this.name,
    this.avatar,
    required this.createdAt,
    this.platform,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      platform: json['platform'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'avatar': avatar,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'platform': platform,
    };
  }
}
