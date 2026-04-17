class DeploymentFile {
  final String name;
  final String type; // file, directory
  final String? uid;
  final String? link; // URL to fetch file content (from file-tree API)
  final String? mode;
  final String? contentType;
  List<DeploymentFile>? children; // Not final - can be updated for lazy loading
  
  // UI state properties (not serialized)
  bool isExpanded;
  bool isLoading;
  bool hasLoadedChildren; // Track if children have been fetched (lazy loading)

  DeploymentFile({
    required this.name,
    required this.type,
    this.uid,
    this.link,
    this.mode,
    this.contentType,
    this.children,
    this.isExpanded = false,
    this.isLoading = false,
    this.hasLoadedChildren = false,
  });

  factory DeploymentFile.fromJson(Map<String, dynamic> json) {
    return DeploymentFile(
      name: json['name'] as String,
      type: json['type'] as String,
      uid: json['uid'] as String?,
      link: json['link'] as String?,
      mode: json['mode']?.toString(),
      contentType: json['contentType'] as String? ?? json['mime'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => DeploymentFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
