class EnvVar {
  final String id;
  final String key;
  final String? value;
  final String type;
  final List<String> target;
  final String? gitBranch;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool? encrypted;

  EnvVar({
    required this.id,
    required this.key,
    this.value,
    required this.type,
    required this.target,
    this.gitBranch,
    required this.createdAt,
    this.updatedAt,
    this.encrypted,
  });

  factory EnvVar.fromJson(Map<String, dynamic> json) {
    // Handle timestamp as either int or string
    int parseTimestamp(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return EnvVar(
      id: json['id'] as String? ?? json['key'] as String,
      key: json['key'] as String,
      value: json['value'] as String?,
      type: json['type'] as String? ?? 'plain',
      target: (json['target'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      gitBranch: json['gitBranch'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(parseTimestamp(json['createdAt'])),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(parseTimestamp(json['updatedAt']))
          : null,
      encrypted: json['encrypted'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'type': type,
      'target': target,
      if (gitBranch != null) 'gitBranch': gitBranch,
    };
  }

  bool get isSecret => type == 'secret' || type == 'encrypted' || (encrypted ?? false);

  String get displayValue => isSecret ? '••••••••' : (value ?? '');
}
