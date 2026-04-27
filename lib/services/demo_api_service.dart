import '../models/deployment.dart';
import '../models/deployment_file.dart';
import '../models/domain.dart';
import '../models/log.dart';
import '../models/project.dart';
import '../models/security.dart';
import '../models/analytics.dart';
import 'api_service.dart';
import 'demo_data.dart';

/// Exception thrown when a user tries to perform a write action while in demo
/// mode. Screens can catch this to show a friendly "connect your account" CTA.
class DemoModeException extends VercelApiException {
  DemoModeException([String? message])
      : super(
          message ?? 'This action is not available in demo mode. Connect your Vercel account to continue.',
          statusCode: 403,
          code: 'demo_mode',
        );
}

/// A [VercelApi] subclass that returns hard-coded, realistic demo data
/// instead of performing network calls. Used when the user chooses
/// "Try with demo data" on the login screen.
class DemoVercelApi extends VercelApi {
  DemoVercelApi() : super(teamId: DemoData.demoTeamId);

  // ---------------------------------------------------------------------------
  // READ – overridden with demo data
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> fetchUserInfoAndSetTeamId() async {
    teamId = DemoData.demoTeamId;
    return DemoData.buildUserResponse();
  }

  @override
  Future<Map<String, dynamic>> getUser() async {
    return {'user': DemoData.buildUserResponse()};
  }

  @override
  Future<Map<String, dynamic>> getTeams() async {
    return DemoData.buildTeamsResponse();
  }

  @override
  Future<Map<String, dynamic>> getProjects({
    String? from,
    String? gitForkProtection,
    String? limit,
    String? search,
    String? repo,
    String? repoId,
    String? repoUrl,
    String? excludeRepos,
    String? edgeConfigId,
    String? edgeConfigTokenId,
    bool? deprecated,
    String? elasticConcurrencyEnabled,
    String? staticIpsEnabled,
    String? buildMachineTypes,
    String? buildQueueConfiguration,
  }) async {
    return {
      'projects': DemoData.buildProjects().map(_projectToJson).toList(),
    };
  }

  @override
  Future<List<Project>> getProjectsList({
    String? from,
    String? gitForkProtection,
    String? limit,
    String? search,
    String? repo,
    String? repoId,
    String? repoUrl,
    String? excludeRepos,
    String? edgeConfigId,
    String? edgeConfigTokenId,
    bool? deprecated,
    String? elasticConcurrencyEnabled,
    String? staticIpsEnabled,
    String? buildMachineTypes,
    String? buildQueueConfiguration,
  }) async {
    var projects = DemoData.buildProjects();
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      projects = projects.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return projects;
  }

  @override
  Future<List<Deployment>> getDeployments({String? projectId}) async {
    final projects = DemoData.buildProjects();
    if (projectId != null) {
      final project = projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => projects.first,
      );
      return DemoData.buildDeployments(project);
    }
    // Return a mixed list from all projects if no projectId specified.
    final all = <Deployment>[];
    for (final p in projects) {
      all.addAll(DemoData.buildDeployments(p).take(3));
    }
    all.sort((a, b) => b.created.compareTo(a.created));
    return all;
  }

  @override
  Future<List<dynamic>> getProjectEnvVars(String projectId) async {
    return DemoData.buildEnvVars(projectId).map((e) => e.toJson()..['id'] = e.id).toList();
  }

  @override
  Future<List<dynamic>> getProjectDomains(String projectId) async {
    final project = DemoData.buildProjects().firstWhere(
      (p) => p.id == projectId,
      orElse: () => DemoData.buildProjects().first,
    );
    return DemoData.buildProjectDomains(project);
  }

  @override
  Future<List<Domain>> getDomains() async {
    return DemoData.buildDomains();
  }

  @override
  Future<List<Map<String, dynamic>>> getDomainDnsRecords(String domain) async {
    return DemoData.buildDnsRecords(domain);
  }

  @override
  Future<Map<String, dynamic>> getDomainConfiguration(String domain) async {
    return {
      'configuredBy': 'A',
      'nameservers': ['ns1.vercel-dns.com', 'ns2.vercel-dns.com'],
      'serviceType': 'external',
      'cnames': const <String>[],
      'aValues': const ['76.76.21.21'],
      'misconfigured': false,
    };
  }

  @override
  Future<Map<String, dynamic>> getUsage({
    required String from,
    String? to,
    String? projectId,
  }) async {
    return DemoData.buildUsage();
  }

  @override
  Future<Map<String, dynamic>> getBilling({
    required String from,
    required String to,
  }) async {
    return DemoData.buildBilling();
  }

  // ---------------------------------------------------------------------------
  // ANALYTICS – overridden with demo data
  // ---------------------------------------------------------------------------

  @override
  Future<AnalyticsOverview> getAnalyticsOverview({
    required String projectId,
    required String from,
    required String to,
  }) async {
    return DemoData.buildAnalyticsOverview(from: from, projectId: projectId);
  }

  @override
  Future<List<TimeseriesPoint>> getAnalyticsTimeseries({
    required String projectId,
    required String from,
    required String to,
  }) async {
    return DemoData.buildAnalyticsTimeseries(from, to, projectId: projectId);
  }

  @override
  Future<List<BreakdownItem>> getAnalyticsBreakdown({
    required String projectId,
    required String from,
    required String to,
    required String groupBy,
  }) async {
    return DemoData.buildAnalyticsBreakdown(groupBy, projectId: projectId);
  }

  @override
  Future<List<dynamic>> getDeploymentEvents(String deploymentId) async {
    return DemoData.buildDeploymentEvents(deploymentId);
  }

  @override
  Future<List<DeploymentFile>> getDeploymentFiles(String deploymentId) async {
    return DemoData.buildDeploymentFiles(deploymentId);
  }

  @override
  Future<List<DeploymentFile>> getDeploymentFileTree({
    required String deploymentUrl,
    String base = 'src',
  }) async {
    return DemoData.buildDeploymentFiles(deploymentUrl);
  }

  @override
  Future<String> getDeploymentFileContents(String deploymentId, String fileId) async {
    // Extract file name from fileId (format: file_page, file_layout, etc.)
    final fileName = fileId.replaceAll('file_', '').replaceAll('dir_', '');
    return DemoData.getDemoFileContent(fileName);
  }

  @override
  Future<String> fetchFileFromUrl(String fileUrl) async {
    // Handle demo:// URLs
    if (fileUrl.startsWith('demo://file/')) {
      // Extract file name from URL (e.g., demo://file/page.tsx -> page.tsx)
      final fileName = fileUrl.replaceFirst('demo://file/', '');
      return DemoData.getDemoFileContent(fileName);
    }
    return '// File contents are not available in demo mode.\n';
  }

  @override
  Future<List<Map<String, dynamic>>> getDeploymentRuntimeLogs({
    required String projectId,
    required String deploymentId,
    int? limit,
    int? since,
    int? until,
    int timeoutSeconds = 5,
  }) async {
    final logs = DemoData.buildRuntimeLogs();
    if (limit != null && logs.length > limit) return logs.sublist(0, limit);
    return logs;
  }

  @override
  Future<List<Map<String, dynamic>>> getDeploymentBuildLogs({
    required String projectId,
    required String deploymentId,
  }) async {
    final events = DemoData.buildDeploymentEvents(deploymentId);
    return events.cast<Map<String, dynamic>>();
  }

  @override
  Future<ProjectLogsResult> getProjectLogs({
    required String projectId,
    required String ownerId,
    String? deploymentId,
    String? startDate,
    String? endDate,
    int? page,
    Map<String, List<String>>? attributes,
  }) async {
    final data = DemoData.buildProjectLogsResponse(projectId);
    final rows = data['rows'] as List<dynamic>;
    return ProjectLogsResult(
      logs: rows
          .map((json) => Log.fromJson(json as Map<String, dynamic>))
          .toList(),
      hasMoreRows: false,
      nextPage: null,
    );
  }

  @override
  Future<Map<String, List<LogFilterValue>>> getProjectLogsFilters({
    required String projectId,
    required List<String> attributes,
    String? startDate,
    String? endDate,
  }) async {
    return {for (final a in attributes) a: <LogFilterValue>[]};
  }

  @override
  Future<AttackModeStatus> getAttackModeStatus(String projectId) async {
    return DemoData.buildAttackMode();
  }

  @override
  Future<FirewallConfig> getFirewallConfig(String projectId) async {
    return DemoData.buildFirewallConfig();
  }

  @override
  Future<List<ManagedRuleset>> getManagedRulesets(String projectId) async {
    return DemoData.buildFirewallConfig().managedRulesets;
  }

  @override
  Future<List<ActiveAttack>> getActiveAttacks({
    required String projectId,
    int? limit,
    DateTime? since,
  }) async {
    return DemoData.buildActiveAttacks();
  }

  @override
  Future<String?> getProjectFavicon(String projectId) async {
    // Map each demo project to its real production URL for a nicer favicon.
    final project = DemoData.buildProjects().firstWhere(
      (p) => p.id == projectId,
      orElse: () => DemoData.buildProjects().first,
    );
    final host = project.allUrls.isNotEmpty ? project.allUrls.first : '${project.name}.vercel.app';
    return 'https://$host/favicon.ico';
  }

  // ---------------------------------------------------------------------------
  // WRITE – blocked in demo mode
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> addDomain(String projectId, String domainName) async {
    throw DemoModeException();
  }

  @override
  Future<Map<String, dynamic>> removeDomain(String projectId, String domain) async {
    throw DemoModeException();
  }

  @override
  Future<Map<String, dynamic>> verifyDomain(String projectId, String domain) async {
    throw DemoModeException();
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
      String domain, Map<String, dynamic> record) async {
    throw DemoModeException();
  }

  @override
  Future<void> deleteDnsRecord(String domain, String recordId) async {
    throw DemoModeException();
  }

  @override
  Future<List<dynamic>> createEnvVars(
      String projectId, List<Map<String, dynamic>> envVars) async {
    throw DemoModeException();
  }

  @override
  Future<List<dynamic>> updateEnvVar(
      String projectId, String envVarId, Map<String, dynamic> envVar) async {
    throw DemoModeException();
  }

  @override
  Future<void> deleteEnvVar(String projectId, String envVarId, {String? target}) async {
    throw DemoModeException();
  }

  @override
  Future<String> getDecryptedEnvVar(String projectId, String envVarId) async {
    throw DemoModeException('Secret values are hidden in demo mode.');
  }

  @override
  Future<Map<String, dynamic>> inviteTeamMember(
      String teamId, String email, {String role = 'MEMBER'}) async {
    throw DemoModeException();
  }

  @override
  Future<Map<String, dynamic>> createProject({
    required String name,
    required String repo,
    String? framework,
    String? rootDirectory,
    List<Map<String, dynamic>>? environmentVariables,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<Deployment> createDeployment({
    required String projectId,
    String? target,
    bool withLatestCommit = true,
    Map<String, dynamic>? projectSettings,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<Map<String, dynamic>> promoteDeployment({
    required String projectId,
    required String deploymentId,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<Map<String, dynamic>> rollbackDeployment({
    required String projectId,
    required String deploymentId,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<Map<String, dynamic>> cancelDeployment({
    required String projectId,
    required String deploymentId,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<AttackModeStatus> updateAttackMode({
    required String projectId,
    required bool enabled,
    DateTime? activeUntil,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<FirewallConfig> updateFirewallConfig({
    required String projectId,
    List<FirewallRule>? rules,
    List<String>? ips,
    List<ManagedRuleset>? managedRulesets,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<void> blockIp({
    required String projectId,
    required String ip,
    String? note,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<void> addFirewallRule({
    required String projectId,
    required String name,
    required String action,
    String? ip,
    String? hostname,
    int? rateLimit,
    String? rateLimitWindow,
    int? statusCode,
    String? redirectLocation,
  }) async {
    throw DemoModeException();
  }

  @override
  Future<void> updateManagedRuleset({
    required String projectId,
    required String rulesetId,
    required bool enabled,
    String action = 'challenge',
  }) async {
    throw DemoModeException();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _projectToJson(Project p) {
    return {
      'id': p.id,
      'name': p.name,
      'accountId': p.accountId,
      'framework': p.framework,
      'nodeVersion': p.nodeVersion,
      'buildCommand': p.buildCommand,
      'devCommand': p.devCommand,
      'installCommand': p.installCommand,
      'outputDirectory': p.outputDirectory,
      'rootDirectory': p.rootDirectory,
      'createdAt': p.createdAt.millisecondsSinceEpoch,
      'updatedAt': p.updatedAt.millisecondsSinceEpoch,
      'live': p.live,
      'paused': p.paused,
      'targets': p.targets,
      'latestDeployments': p.latestDeployments,
      'link': p.link,
      'alias': p.alias,
      'analytics': p.analytics,
      'webAnalytics': p.webAnalytics,
      'security': p.security,
    };
  }
}
