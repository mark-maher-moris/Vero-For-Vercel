class Deployment {
  final String uid;
  final String name;
  final String url;
  final int created;
  final String state; // READY, ERROR, BUILDING
  final String? inspectorUrl;

  Deployment({
    required this.uid,
    required this.name,
    required this.url,
    required this.created,
    required this.state,
    this.inspectorUrl,
  });

  factory Deployment.fromJson(Map<String, dynamic> json) {
    return Deployment(
      uid: json['uid'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      created: json['created'] as int,
      state: json['state'] as String,
      inspectorUrl: json['inspectorUrl'] as String?,
    );
  }
}
