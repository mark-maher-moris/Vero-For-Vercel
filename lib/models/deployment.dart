class Deployment {
  final String uid;
  final String name;
  final String url;
  final int created;
  final String state; // READY, ERROR, BUILDING, INITIALIZING, QUEUED, CANCELED
  final String? inspectorUrl;
  final String? projectId;
  final String? target; // production, staging
  final String? source; // git, cli, redeploy, import, etc.
  final Map<String, String>? meta; // git metadata: githubCommitRef, githubCommitSha, githubCommitMessage, etc.
  final DeploymentCreator? creator;
  final String? errorCode;
  final String? errorMessage;
  final String? readySubstate; // STAGED, ROLLING, PROMOTED
  final bool? isRollbackCandidate;
  final int? buildingAt;
  final int? ready;
  final String? checksState; // registered, running, completed
  final String? checksConclusion; // succeeded, failed, skipped, canceled

  Deployment({
    required this.uid,
    required this.name,
    required this.url,
    required this.created,
    required this.state,
    this.inspectorUrl,
    this.projectId,
    this.target,
    this.source,
    this.meta,
    this.creator,
    this.errorCode,
    this.errorMessage,
    this.readySubstate,
    this.isRollbackCandidate,
    this.buildingAt,
    this.ready,
    this.checksState,
    this.checksConclusion,
  });

  factory Deployment.fromJson(Map<String, dynamic> json) {
    final metaData = json['meta'];
    final creatorData = json['creator'];
    
    return Deployment(
      uid: json['uid'] as String,
      name: json['name'] as String,
      url: json['url'] as String? ?? '',
      created: json['created'] as int,
      state: json['state'] as String? ?? json['readyState'] as String? ?? 'UNKNOWN',
      inspectorUrl: json['inspectorUrl'] as String?,
      projectId: json['projectId'] as String?,
      target: json['target'] as String?,
      source: json['source'] as String?,
      meta: metaData != null 
        ? Map<String, String>.from(metaData as Map) 
        : null,
      creator: creatorData != null 
        ? DeploymentCreator.fromJson(creatorData as Map<String, dynamic>) 
        : null,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
      readySubstate: json['readySubstate'] as String?,
      isRollbackCandidate: json['isRollbackCandidate'] as bool?,
      buildingAt: json['buildingAt'] as int?,
      ready: json['ready'] as int?,
      checksState: json['checksState'] as String?,
      checksConclusion: json['checksConclusion'] as String?,
    );
  }

  String get branch => meta?['githubCommitRef'] ?? meta?['gitlabCommitRef'] ?? 'main';
  
  String get commitSha {
    final sha = meta?['githubCommitSha'] ?? meta?['gitlabCommitSha'];
    return sha != null && sha.length > 7 ? sha.substring(0, 7) : sha ?? 'unknown';
  }
  
  String get commitMessage => meta?['githubCommitMessage'] ?? meta?['gitlabCommitMessage'] ?? '';
  
  String get deployerName {
    if (creator?.username != null) return creator!.username!;
    if (creator?.githubLogin != null) return creator!.githubLogin!;
    if (creator?.email != null) return creator!.email!.split('@').first;
    return 'unknown';
  }

  String get formattedDuration {
    if (buildingAt == null || ready == null) return '';
    final duration = Duration(milliseconds: ready! - buildingAt!);
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }
}

class DeploymentCreator {
  final String uid;
  final String? email;
  final String? username;
  final String? githubLogin;
  final String? gitlabLogin;

  DeploymentCreator({
    required this.uid,
    this.email,
    this.username,
    this.githubLogin,
    this.gitlabLogin,
  });

  factory DeploymentCreator.fromJson(Map<String, dynamic> json) {
    return DeploymentCreator(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      githubLogin: json['githubLogin'] as String?,
      gitlabLogin: json['gitlabLogin'] as String?,
    );
  }
}
