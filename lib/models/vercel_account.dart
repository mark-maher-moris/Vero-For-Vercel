class VercelAccount {
  final String id;
  final String token;
  final String? teamScope;
  final String name;
  final String username;
  final String? email;
  final String? avatar;
  final String? defaultTeamId;
  final DateTime createdAt;
  final bool isTeamScopedOnly;

  VercelAccount({
    required this.id,
    required this.token,
    this.teamScope,
    required this.name,
    required this.username,
    this.email,
    this.avatar,
    this.defaultTeamId,
    required this.createdAt,
    this.isTeamScopedOnly = false,
  });

  /// Generate a display avatar URL or fallback
  String? get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    if (avatar!.startsWith('http://') || avatar!.startsWith('https://')) {
      return avatar;
    }
    return 'https://vercel.com/api/www/avatar/$avatar';
  }

  factory VercelAccount.fromJson(Map<String, dynamic> json) {
    return VercelAccount(
      id: json['id'] as String? ?? 'default_account',
      token: json['token'] as String? ?? '',
      teamScope: json['teamScope'] as String?,
      name: json['name'] as String? ?? json['username'] as String? ?? 'Account',
      username: json['username'] as String? ?? 'user',
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      defaultTeamId: json['defaultTeamId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isTeamScopedOnly: json['isTeamScopedOnly'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'teamScope': teamScope,
      'name': name,
      'username': username,
      'email': email,
      'avatar': avatar,
      'defaultTeamId': defaultTeamId,
      'createdAt': createdAt.toIso8601String(),
      'isTeamScopedOnly': isTeamScopedOnly,
    };
  }

  VercelAccount copyWith({
    String? id,
    String? token,
    String? teamScope,
    String? name,
    String? username,
    String? email,
    String? avatar,
    String? defaultTeamId,
    DateTime? createdAt,
    bool? isTeamScopedOnly,
  }) {
    return VercelAccount(
      id: id ?? this.id,
      token: token ?? this.token,
      teamScope: teamScope ?? this.teamScope,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      defaultTeamId: defaultTeamId ?? this.defaultTeamId,
      createdAt: createdAt ?? this.createdAt,
      isTeamScopedOnly: isTeamScopedOnly ?? this.isTeamScopedOnly,
    );
  }
}
