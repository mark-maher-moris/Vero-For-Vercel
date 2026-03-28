class Domain {
  final String id;
  final String name;
  final bool verified;
  final List<String>? verification;
  final String? redirect;
  final bool? redirectStatusCode;
  final String? projectId;
  final DateTime createdAt;

  Domain({
    required this.id,
    required this.name,
    required this.verified,
    this.verification,
    this.redirect,
    this.redirectStatusCode,
    this.projectId,
    required this.createdAt,
  });

  factory Domain.fromJson(Map<String, dynamic> json) {
    return Domain(
      id: json['id'] as String? ?? json['name'] as String,
      name: json['name'] as String,
      verified: json['verified'] as bool? ?? false,
      verification: (json['verification'] as List<dynamic>?)
          ?.map((e) => e['type'] as String? ?? e.toString())
          .toList(),
      redirect: json['redirect'] as String?,
      redirectStatusCode: json['redirectStatusCode'] != null
          ? (json['redirectStatusCode'] as num).toInt() == 301
          : null,
      projectId: json['projectId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (redirect != null) 'redirect': redirect,
      if (redirectStatusCode != null) 'redirectStatusCode': redirectStatusCode! ? 301 : 307,
    };
  }
}
