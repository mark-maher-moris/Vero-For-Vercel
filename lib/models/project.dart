class Project {
  final String id;
  final String name;
  final String? accountId;
  final String? framework;
  final DateTime updatedAt;
  final List<dynamic>? latestDeployments;

  Project({
    required this.id,
    required this.name,
    this.accountId,
    this.framework,
    required this.updatedAt,
    this.latestDeployments,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      accountId: json['accountId'] as String?,
      framework: json['framework'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      latestDeployments: json['latestDeployments'] as List<dynamic>?,
    );
  }
}

