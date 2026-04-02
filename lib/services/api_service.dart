import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/domain.dart';
import '../models/project.dart';
import '../models/deployment.dart';
import '../models/security.dart';
import 'auth_service.dart';

class VercelApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  VercelApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'VercelApiException: $message (Status: $statusCode, Code: $code)';
}

class VercelApi {
  static const String baseUrl = 'https://api.vercel.com';
  final AuthService _authService = AuthService();
  final String? teamId;

  VercelApi({this.teamId});

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw VercelApiException('No access token found', statusCode: 401);
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final params = Map<String, String>.from(queryParameters ?? {});
    if (teamId != null) {
      params['teamId'] = teamId!;
    }
    
    return Uri.parse('$baseUrl$path').replace(queryParameters: params.isNotEmpty ? params : null);
  }

  /// Truncate ISO 8601 string to millisecond precision (Vercel API compatibility)
  /// Dart's toIso8601String() includes microseconds which Vercel rejects
  String _truncateIso8601(String isoDate) {
    // Remove microseconds if present (e.g., 2026-04-02T00:18:15.885942Z → 2026-04-02T00:18:15.885Z)
    if (isoDate.contains('.') && isoDate.endsWith('Z')) {
      final dotIndex = isoDate.lastIndexOf('.');
      final zIndex = isoDate.length - 1;
      final fraction = isoDate.substring(dotIndex + 1, zIndex);
      if (fraction.length > 3) {
        return '${isoDate.substring(0, dotIndex + 1)}${fraction.substring(0, 3)}Z';
      }
    }
    return isoDate;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final dynamic data = json.decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      String message = 'An unexpected error occurred';
      String? code;
      
      if (data is Map && data.containsKey('error')) {
        final error = data['error'];
        if (error is Map) {
          message = error['message'] ?? message;
          code = error['code'];
        } else if (error is String) {
          message = error;
        }
      }
      
      print('Vercel API Error: $message (Status: ${response.statusCode})');
      print('  → Endpoint: ${response.request?.method} ${response.request?.url}');
      print('  → Response Body: ${response.body}');
      print('  → Timestamp: ${DateTime.now().toIso8601String()}');
      throw VercelApiException(message, statusCode: response.statusCode, code: code);
    }
  }

  Future<Map<String, dynamic>> getTeams() async {
    final response = await http.get(
      _buildUri('/v2/teams'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  /// Get all domains for the authenticated user or team
  /// Uses v5/domains endpoint for efficient global domain listing
  Future<List<Domain>> getDomains() async {
    final response = await http.get(
      _buildUri('/v5/domains'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    final List domainsJson = data['domains'] as List? ?? [];
    return domainsJson.map((json) => Domain.fromJson(json)).toList();
  }

  /// Get DNS records for a specific domain
  /// Uses v5/domains/{domain}/records endpoint
  Future<List<Map<String, dynamic>>> getDomainDnsRecords(String domain) async {
    final response = await http.get(
      _buildUri('/v5/domains/$domain/records'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    final records = data['records'] as List<dynamic>? ?? [];
    return records.cast<Map<String, dynamic>>();
  }

  /// Create a new DNS record for a domain
  Future<Map<String, dynamic>> createDnsRecord(String domain, Map<String, dynamic> record) async {
    final response = await http.post(
      _buildUri('/v5/domains/$domain/records'),
      headers: await _getHeaders(),
      body: json.encode(record),
    );
    return await _handleResponse(response);
  }

  /// Delete a DNS record for a domain
  Future<void> deleteDnsRecord(String domain, String recordId) async {
    final response = await http.delete(
      _buildUri('/v5/domains/$domain/records/$recordId'),
      headers: await _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUser() async {
    final response = await http.get(
      _buildUri('/v2/user'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

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
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (gitForkProtection != null) params['gitForkProtection'] = gitForkProtection;
    if (limit != null) params['limit'] = limit;
    if (search != null) params['search'] = search;
    if (repo != null) params['repo'] = repo;
    if (repoId != null) params['repoId'] = repoId;
    if (repoUrl != null) params['repoUrl'] = repoUrl;
    if (excludeRepos != null) params['excludeRepos'] = excludeRepos;
    if (edgeConfigId != null) params['edgeConfigId'] = edgeConfigId;
    if (edgeConfigTokenId != null) params['edgeConfigTokenId'] = edgeConfigTokenId;
    if (deprecated != null) params['deprecated'] = deprecated.toString();
    if (elasticConcurrencyEnabled != null) params['elasticConcurrencyEnabled'] = elasticConcurrencyEnabled;
    if (staticIpsEnabled != null) params['staticIpsEnabled'] = staticIpsEnabled;
    if (buildMachineTypes != null) params['buildMachineTypes'] = buildMachineTypes;
    if (buildQueueConfiguration != null) params['buildQueueConfiguration'] = buildQueueConfiguration;

    final response = await http.get(
      _buildUri('/v10/projects', params.isNotEmpty ? params : null),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

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
    final data = await getProjects(
      from: from,
      gitForkProtection: gitForkProtection,
      limit: limit,
      search: search,
      repo: repo,
      repoId: repoId,
      repoUrl: repoUrl,
      excludeRepos: excludeRepos,
      edgeConfigId: edgeConfigId,
      edgeConfigTokenId: edgeConfigTokenId,
      deprecated: deprecated,
      elasticConcurrencyEnabled: elasticConcurrencyEnabled,
      staticIpsEnabled: staticIpsEnabled,
      buildMachineTypes: buildMachineTypes,
      buildQueueConfiguration: buildQueueConfiguration,
    );
    final List projectsJson = data['projects'] as List? ?? [];
    return projectsJson.map((json) => Project.fromJson(json)).toList();
  }

  Future<List<Deployment>> getDeployments({String? projectId}) async {
    final params = <String, String>{};
    if (projectId != null) params['projectId'] = projectId;
    
    final response = await http.get(
      _buildUri('/v6/deployments', params),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    final list = data['deployments'] as List<dynamic>? ?? [];
    return list.map((json) => Deployment.fromJson(json)).toList();
  }

  Future<List<dynamic>> getProjectEnvVars(String projectId) async {
    final response = await http.get(
      _buildUri('/v9/projects/$projectId/env'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['envs'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getProjectDomains(String projectId) async {
    final response = await http.get(
      _buildUri('/v9/projects/$projectId/domains'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['domains'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getDeploymentEvents(String deploymentId) async {
    final response = await http.get(
      _buildUri('/v3/deployments/$deploymentId/events'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data is List) return data;
        return [data];
      } catch (e) {
        final lines = response.body.split('\n').where((l) => l.trim().isNotEmpty);
        return lines.map((l) => json.decode(l)).toList();
      }
    } else {
      return await _handleResponse(response);
    }
  }

  Future<Map<String, dynamic>> addDomain(String projectId, String domainName) async {
    final response = await http.post(
      _buildUri('/v9/projects/$projectId/domains'),
      headers: await _getHeaders(),
      body: json.encode({'name': domainName}),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeDomain(String projectId, String domain) async {
    final response = await http.delete(
      _buildUri('/v9/projects/$projectId/domains/$domain'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyDomain(String projectId, String domain) async {
    final response = await http.post(
      _buildUri('/v9/projects/$projectId/domains/$domain/verify'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<List<dynamic>> createEnvVars(String projectId, List<Map<String, dynamic>> envVars) async {
    final response = await http.post(
      _buildUri('/v9/projects/$projectId/env'),
      headers: await _getHeaders(),
      body: json.encode(envVars),
    );
    final data = await _handleResponse(response);
    return data['envs'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> updateEnvVar(String projectId, String envVarId, Map<String, dynamic> envVar) async {
    final response = await http.patch(
      _buildUri('/v9/projects/$projectId/env/$envVarId'),
      headers: await _getHeaders(),
      body: json.encode(envVar),
    );
    final data = await _handleResponse(response);
    return data['envs'] as List<dynamic>? ?? [];
  }

  Future<void> deleteEnvVar(String projectId, String envVarId, {String? target}) async {
    final params = <String, String>{};
    if (target != null) params['target'] = target;
    
    final response = await http.delete(
      _buildUri('/v9/projects/$projectId/env/$envVarId', params.isNotEmpty ? params : null),
      headers: await _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> inviteTeamMember(String teamId, String email, {String role = 'MEMBER'}) async {
    final response = await http.post(
      _buildUri('/v2/teams/$teamId/members'),
      headers: await _getHeaders(),
      body: json.encode({'email': email, 'role': role}),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUsage({required String from, String? to, String? projectId}) async {
    final params = <String, String>{
      'from': _truncateIso8601(from),
    };
    if (to != null) params['to'] = _truncateIso8601(to);
    if (projectId != null) params['projectId'] = projectId;
    
    final response = await http.get(
      _buildUri('/v1/usage', params),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getBilling({required String from, required String to}) async {
    final params = <String, String>{
      'from': from,
      'to': to,
    };
    
    final response = await http.get(
      _buildUri('/v1/billing/charges', params),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  /// Create a new project from a GitHub repository
  /// [name] - Project name
  /// [repo] - GitHub repository in format 'owner/repo'
  /// [framework] - Optional framework (nextjs, etc.)
  /// [rootDirectory] - Optional subdirectory to deploy from
  Future<Map<String, dynamic>> createProject({
    required String name,
    required String repo,
    String? framework,
    String? rootDirectory,
    List<Map<String, dynamic>>? environmentVariables,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'gitRepository': {
        'type': 'github',
        'repo': repo,
      },
      'framework': framework,
      'rootDirectory': rootDirectory,
      'environmentVariables': environmentVariables,
    }..removeWhere((key, value) => value == null);

    final response = await http.post(
      _buildUri('/v11/projects'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    return await _handleResponse(response);
  }

  /// Create a new deployment for a project
  /// [projectId] - The ID of the project to deploy
  /// [target] - The target environment ('production' or 'preview')
  /// [withLatestCommit] - Whether to use the latest commit from the Git repository
  /// [projectSettings] - Optional build settings to override project defaults
  Future<Deployment> createDeployment({
    required String projectId,
    String? target,
    bool withLatestCommit = true,
    Map<String, dynamic>? projectSettings,
  }) async {
    final body = <String, dynamic>{
      'project': projectId,
      'withLatestCommit': withLatestCommit,
    };

    if (target != null) {
      body['target'] = target;
    }

    if (projectSettings != null) {
      body['projectSettings'] = projectSettings;
    }

    final response = await http.post(
      _buildUri('/v13/deployments'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    final data = await _handleResponse(response);
    return Deployment.fromJson(data);
  }

  // ==================== SECURITY API ====================

  /// Get the attack challenge mode status for a project
  /// [projectId] - The project ID to check
  Future<AttackModeStatus> getAttackModeStatus(String projectId) async {
    final response = await http.get(
      _buildUri('/v1/security/attack-mode', {'projectId': projectId}),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return AttackModeStatus.fromJson(data);
  }

  /// Enable or disable attack challenge mode for a project
  /// [projectId] - The project ID to update
  /// [enabled] - Whether to enable or disable attack mode
  /// [activeUntil] - Optional timestamp when attack mode should auto-disable
  Future<AttackModeStatus> updateAttackMode({
    required String projectId,
    required bool enabled,
    DateTime? activeUntil,
  }) async {
    final body = <String, dynamic>{
      'projectId': projectId,
      'attackModeEnabled': enabled.toString(),
    };

    if (activeUntil != null) {
      body['attackModeActiveUntil'] = activeUntil.millisecondsSinceEpoch.toString();
    }

    final response = await http.post(
      _buildUri('/v1/security/attack-mode', {'projectId': projectId}),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    final data = await _handleResponse(response);
    return AttackModeStatus.fromJson(data);
  }

  /// Get the firewall configuration for a project
  /// [projectId] - The project ID
  Future<FirewallConfig> getFirewallConfig(String projectId) async {
    final response = await http.get(
      _buildUri('/v1/security/firewall/config', {'projectId': projectId}),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return FirewallConfig.fromJson(data);
  }

  /// Update firewall configuration for a project
  /// [projectId] - The project ID
  /// [rules] - List of firewall rules to set
  /// [ips] - List of IP addresses to block/allow
  /// [managedRulesets] - List of managed rulesets configuration
  Future<FirewallConfig> updateFirewallConfig({
    required String projectId,
    List<FirewallRule>? rules,
    List<String>? ips,
    List<ManagedRuleset>? managedRulesets,
  }) async {
    final body = <String, dynamic>{};

    if (rules != null) {
      body['rules'] = rules.map((r) => r.toJson()).toList();
    }
    if (ips != null) {
      body['ips'] = ips;
    }
    if (managedRulesets != null) {
      body['managedRulesets'] = managedRulesets.map((r) => r.toJson()).toList();
    }

    final response = await http.post(
      _buildUri('/v1/security/firewall/config', {'projectId': projectId}),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    final data = await _handleResponse(response);
    return FirewallConfig.fromJson(data);
  }

  /// Block an IP address for a project
  /// [projectId] - The project ID
  /// [ip] - IP address or CIDR range to block
  /// [note] - Optional note explaining why
  Future<void> blockIp({
    required String projectId,
    required String ip,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'action': 'deny',
      'ip': ip,
      if (note != null) 'note': note,
    };

    final response = await http.post(
      _buildUri('/v1/security/firewall/config', {'projectId': projectId}),
      headers: await _getHeaders(),
      body: json.encode(body),
    );
    await _handleResponse(response);
  }

  /// Add a firewall rule with specific conditions
  /// [projectId] - The project ID
  /// [name] - Rule name
  /// [action] - Action to take: 'deny', 'challenge', 'log', 'rate_limit', 'redirect'
  /// [ip] - Optional IP address or CIDR to match
  /// [hostname] - Optional hostname to match
  /// [rateLimit] - Optional rate limit (requests per window)
  /// [rateLimitWindow] - Optional rate limit window (e.g., '1m', '1h')
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
    final body = <String, dynamic>{
      'name': name,
      'action': action,
      if (ip != null) 'ip': ip,
      if (hostname != null) 'hostname': hostname,
      if (rateLimit != null) 'rateLimit': rateLimit.toString(),
      if (rateLimitWindow != null) 'rateLimitWindow': rateLimitWindow,
      if (statusCode != null) 'statusCode': statusCode.toString(),
      if (redirectLocation != null) 'redirectLocation': redirectLocation,
    };

    final response = await http.post(
      _buildUri('/v1/security/firewall/config', {'projectId': projectId}),
      headers: await _getHeaders(),
      body: json.encode(body),
    );
    await _handleResponse(response);
  }
  /// [projectId] - The project ID
  Future<List<ManagedRuleset>> getManagedRulesets(String projectId) async {
    final response = await http.get(
      _buildUri('/v1/security/firewall/managed-rulesets', {'projectId': projectId}),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    final List rulesets = data['rulesets'] as List? ?? [];
    return rulesets.map((r) => ManagedRuleset.fromJson(r)).toList();
  }

  /// Update a managed ruleset configuration
  /// [projectId] - The project ID
  /// [rulesetId] - The ruleset ID to update
  /// [enabled] - Whether to enable/disable the ruleset
  /// [action] - Action to take: 'deny', 'challenge', 'log', 'next'
  Future<void> updateManagedRuleset({
    required String projectId,
    required String rulesetId,
    required bool enabled,
    String action = 'challenge',
  }) async {
    final body = <String, dynamic>{
      'id': rulesetId,
      'active': enabled,
      'action': action,
    };

    final response = await http.put(
      _buildUri('/v1/security/firewall/managed-rulesets/$rulesetId', {'projectId': projectId}),
      headers: await _getHeaders(),
      body: json.encode(body),
    );
    await _handleResponse(response);
  }
}

