class DeploymentFile {
  final String name;
  final String type; // file, directory
  final String? uid;
  final String? mode;
  final String? contentType;
  final List<DeploymentFile>? children;

  DeploymentFile({
    required this.name,
    required this.type,
    this.uid,
    this.mode,
    this.contentType,
    this.children,
  });

  factory DeploymentFile.fromJson(Map<String, dynamic> json) {
    return DeploymentFile(
      name: json['name'] as String,
      type: json['type'] as String,
      uid: json['uid'] as String?,
      mode: json['mode']?.toString(),
      contentType: json['contentType'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => DeploymentFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
