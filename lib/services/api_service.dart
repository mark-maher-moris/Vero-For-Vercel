import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/domain.dart';
import '../models/project.dart';
import '../models/deployment.dart';
import '../models/deployment_file.dart';
import '../models/security.dart';
import '../models/log.dart';
import '../models/analytics.dart';
import 'auth_service.dart';

/// Stream controller for broadcasting authentication errors (401/403)
/// This allows the app to globally handle token expiration/invalidation
final StreamController<AuthErrorEvent> _authErrorController = StreamController<AuthErrorEvent>.broadcast();

/// Public stream for listening to authentication errors
Stream<AuthErrorEvent> get authErrorStream => _authErrorController.stream;

/// Event class for authentication errors
class AuthErrorEvent {
  final int statusCode;
  final String message;
  final DateTime timestamp;

  AuthErrorEvent({
    required this.statusCode,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
}

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
  String? teamId; // Made mutable so it can be set automatically

  VercelApi({this.teamId});

  Future<Map<String, String>> _getHeaders() async {
    if (kDebugMode) print('[VercelApi] _getHeaders called - fetching token...');
    final token = await _authService.getToken();
    if (kDebugMode) print('[VercelApi] token retrieved: ${token != null ? 'present' : 'null'}');
    if (token == null) throw VercelApiException('No access token found', statusCode: 401);
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetch user info and automatically set the team ID
  /// This should be called once after authentication with just the token
  Future<Map<String, dynamic>> fetchUserInfoAndSetTeamId() async {
    if (kDebugMode) print('[VercelApi] fetchUserInfoAndSetTeamId called');
    
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/www/user'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      
      if (kDebugMode) print('[VercelApi]   Response status: ${response.statusCode}');
      
      final data = await _handleResponse(response);
      final user = data['user'] as Map<String, dynamic>?;
      
      if (user != null && user.containsKey('defaultTeamId')) {
        teamId = user['defaultTeamId'] as String?;
        if (kDebugMode) print('[VercelApi]   Team ID set automatically: $teamId');
      }
      
      return user ?? {};
    } on TimeoutException catch (_) {
      if (kDebugMode) print('[VercelApi]   Timeout fetching user info');
      throw VercelApiException('Request timed out. Please check your connection and try again.', statusCode: 408);
    } catch (e) {
      if (kDebugMode) print('[VercelApi]   Error fetching user info: $e');
      throw VercelApiException('Failed to fetch user info and team ID', statusCode: 500);
    }
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final params = Map<String, String>.from(queryParameters ?? {});
    if (teamId != null) {
      params['teamId'] = teamId!;
    }
    
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params.isNotEmpty ? params : null);
    if (kDebugMode && path.contains('/files')) {
      print('VercelApi: Building URI for files: $uri (teamId: $teamId)');
    }
    return uri;
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

      // Check for authentication errors (401/403) and broadcast them
      // Per Vercel API docs: auth errors have status 401/403 OR error code 'forbidden'/'unauthorized'
      final isAuthError = response.statusCode == 401 ||
                          response.statusCode == 403 ||
                          code == 'forbidden' ||
                          code == 'unauthorized';
      if (isAuthError) {
        final authError = AuthErrorEvent(
          statusCode: response.statusCode,
          message: message,
        );
        _authErrorController.add(authError);
        if (kDebugMode) print('[VercelApi] Authentication error broadcast: ${response.statusCode} (code: $code) - $message');
      }

      // Don't log 404 "File tree not found" as a scary API error, as it's a known limitation for Git deployments
      if (response.statusCode != 404 || message != 'File tree not found') {
        if (kDebugMode) {
          print('Vercel API Error: $message (Status: ${response.statusCode})');
          print('  → Endpoint: ${response.request?.method} ${response.request?.url}');
          print('  → Response Body: ${response.body}');
          print('  → Timestamp: ${DateTime.now().toIso8601String()}');
        }
      }

      throw VercelApiException(message, statusCode: response.statusCode, code: code);
    }
  }

  Map<String, dynamic> _wrapLogLine(String line) {
    return {
      'message': line,
      'level': 'info',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> getTeams() async {
    final response = await http
        .get(
          _buildUri('/v2/teams'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));
    return await _handleResponse(response);
  }

  /// Get all domains for the authenticated user or team
  /// Uses v5/domains endpoint for efficient global domain listing
  /// Fetches from personal account + all teams to ensure complete domain list
  Future<List<Domain>> getDomains() async {
    if (kDebugMode) print('[VercelApi] getDomains called');
    final allDomains = <Domain>[];
    final seenDomainIds = <String>{};
    
    try {
      // First, fetch domains from personal account (no teamId)
      if (kDebugMode) print('[VercelApi] Fetching domains from personal account...');
      final personalDomains = await _getDomainsForTeam(null);
      for (final domain in personalDomains) {
        if (!seenDomainIds.contains(domain.id)) {
          seenDomainIds.add(domain.id);
          allDomains.add(domain);
        }
      }
      if (kDebugMode) print('[VercelApi] Personal account domains: ${personalDomains.length}');
      
      // Then fetch domains from all teams
      if (kDebugMode) print('[VercelApi] Fetching teams list...');
      final teamsResponse = await getTeams();
      final teams = teamsResponse['teams'] as List<dynamic>? ?? [];
      if (kDebugMode) print('[VercelApi] Found ${teams.length} teams');
      
      for (final team in teams) {
        final teamId = team['id'] as String?;
        if (teamId == null) continue;
        
        if (kDebugMode) print('[VercelApi] Fetching domains for team: $teamId');
        try {
          final teamDomains = await _getDomainsForTeam(teamId);
          if (kDebugMode) print('[VercelApi] Team $teamId domains: ${teamDomains.length}');
          for (final domain in teamDomains) {
            if (!seenDomainIds.contains(domain.id)) {
              seenDomainIds.add(domain.id);
              allDomains.add(domain);
            }
          }
        } catch (e) {
          if (kDebugMode) print('[VercelApi] Error fetching domains for team $teamId: $e');
          // Continue to next team even if one fails
        }
      }
      
      if (kDebugMode) print('[VercelApi] Total unique domains found: ${allDomains.length}');
      return allDomains;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[VercelApi] Error in getDomains: $e');
        print('[VercelApi] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
  
  /// Helper to fetch domains for a specific team (null for personal)
  Future<List<Domain>> _getDomainsForTeam(String? teamId) async {
    final params = <String, String>{};
    if (teamId != null) {
      params['teamId'] = teamId;
    }
    
    final uri = Uri.parse('$baseUrl/v5/domains').replace(
      queryParameters: params.isNotEmpty ? params : null,
    );
    
    if (kDebugMode) print('[VercelApi] _getDomainsForTeam(${teamId ?? 'personal'}) - URI: $uri');
    
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);
    
    if (kDebugMode) print('[VercelApi] Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List domainsJson = data['domains'] as List? ?? [];
      return domainsJson.map((json) => Domain.fromJson(json)).toList();
    }
    
    // Handle errors
    final data = json.decode(response.body);
    String message = 'Failed to fetch domains';
    if (data is Map && data.containsKey('error')) {
      final error = data['error'];
      if (error is Map) message = error['message'] ?? message;
    }
    throw VercelApiException(message, statusCode: response.statusCode);
  }

  /// Get DNS records for a specific domain
  /// Uses v5/domains/{domain}/records endpoint
  Future<List<Map<String, dynamic>>> getDomainDnsRecords(String domain) async {
    try {
      final response = await http.get(
        _buildUri('/v5/domains/$domain/records'),
        headers: await _getHeaders(),
      );
      final data = await _handleResponse(response);
      final records = data['records'] as List<dynamic>? ?? [];
      return records.cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getDomainDnsRecords for domain "$domain": $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Create a new DNS record for a domain
  Future<Map<String, dynamic>> createDnsRecord(String domain, Map<String, dynamic> record) async {
    try {
      final response = await http.post(
        _buildUri('/v5/domains/$domain/records'),
        headers: await _getHeaders(),
        body: json.encode(record),
      );
      return await _handleResponse(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in createDnsRecord for domain "$domain": $e');
        print('Record data: $record');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Delete a DNS record for a domain
  Future<void> deleteDnsRecord(String domain, String recordId) async {
    try {
      final response = await http.delete(
        _buildUri('/v5/domains/$domain/records/$recordId'),
        headers: await _getHeaders(),
      );
      await _handleResponse(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in deleteDnsRecord for domain "$domain", recordId "$recordId": $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
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

    final response = await http
        .get(
          _buildUri('/v10/projects', params.isNotEmpty ? params : null),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));
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
    try {
      final response = await http.get(
        _buildUri('/v9/projects/$projectId/domains'),
        headers: await _getHeaders(),
      );
      final data = await _handleResponse(response);
      return data['domains'] as List<dynamic>? ?? [];
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getProjectDomains for projectId "$projectId": $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
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
    try {
      final response = await http.post(
        _buildUri('/v9/projects/$projectId/domains'),
        headers: await _getHeaders(),
        body: json.encode({'name': domainName}),
      );
      return await _handleResponse(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in addDomain for projectId "$projectId", domain "$domainName": $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeDomain(String projectId, String domain) async {
    try {
      final response = await http.delete(
        _buildUri('/v9/projects/$projectId/domains/$domain'),
        headers: await _getHeaders(),
      );
      return await _handleResponse(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in removeDomain for projectId "$projectId", domain "$domain": $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyDomain(String projectId, String domain) async {
    try {
      final response = await http.post(
        _buildUri('/v9/projects/$projectId/domains/$domain/verify'),
        headers: await _getHeaders(),
      );
      return await _handleResponse(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in verifyDomain for projectId "$projectId", domain "$domain": $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
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

  /// Retrieve the decrypted value of an environment variable
  /// [projectId] - The project ID
  /// [envVarId] - The environment variable ID
  Future<String> getDecryptedEnvVar(String projectId, String envVarId) async {
    final response = await http.get(
      _buildUri('/v1/projects/$projectId/env/$envVarId', {'decrypt': 'true'}),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['value'] as String? ?? '';
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
    
    // Try v4 first (works for hobby plans), fallback to v1 for Pro/Enterprise
    try {
      final response = await http.get(
        _buildUri('/v4/usage', params),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return await _handleResponse(response);
      }
    } catch (e) {
      // v4 failed, try v1 as fallback
    }
    
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

  /// Get active attack data for a project
  /// Returns a list of ongoing or recent DDoS attacks
  /// [projectId] - The project ID to check for active attacks
  /// [limit] - Maximum number of attacks to return (default: 100)
  /// [since] - Only return attacks started after this timestamp
  Future<List<ActiveAttack>> getActiveAttacks({
    required String projectId,
    int? limit,
    DateTime? since,
  }) async {
    final params = <String, String>{
      'projectId': projectId,
    };
    if (limit != null) params['limit'] = limit.toString();
    if (since != null) params['since'] = since.toIso8601String();

    final response = await http.get(
      _buildUri('/v1/security/attacks', params),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    final List attacks = data['attacks'] as List? ?? [];
    return attacks.map((a) => ActiveAttack.fromJson(a as Map<String, dynamic>)).toList();
  }

  // ==================== ANALYTICS API ====================

  Uri _buildAnalyticsUri(String path, [Map<String, String>? queryParameters]) {
    final params = Map<String, String>.from(queryParameters ?? {});
    if (teamId != null) {
      params['teamId'] = teamId!;
    }
    
    // Analytics API uses vercel.com/api instead of api.vercel.com
    return Uri.parse('https://vercel.com/api$path').replace(queryParameters: params.isNotEmpty ? params : null);
  }

  Future<AnalyticsOverview> getAnalyticsOverview({
    required String projectId,
    required String from,
    required String to,
  }) async {
    final response = await http.get(
      _buildAnalyticsUri('/web-analytics/overview', {
        'projectId': projectId,
        'from': from,
        'to': to,
      }),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return AnalyticsOverview.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TimeseriesPoint>> getAnalyticsTimeseries({
    required String projectId,
    required String from,
    required String to,
  }) async {
    final response = await http.get(
      _buildAnalyticsUri('/web-analytics/timeseries', {
        'projectId': projectId,
        'from': from,
        'to': to,
      }),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    final dataObj = data['data'] as Map<String, dynamic>?;
    final groups = dataObj?['groups'] as Map<String, dynamic>?;
    final all = groups?['all'] as List<dynamic>? ?? [];
    return all.map((json) => TimeseriesPoint.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<BreakdownItem>> getAnalyticsBreakdown({
    required String projectId,
    required String from,
    required String to,
    required String groupBy,
  }) async {
    final response = await http.get(
      _buildAnalyticsUri('/web-analytics/timeseries', {
        'projectId': projectId,
        'from': from,
        'to': to,
        'groupBy': groupBy,
      }),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    final dataObj = data['data'] as Map<String, dynamic>?;
    final groups = dataObj?['groups'] as Map<String, dynamic>? ?? {};
    
    final results = <BreakdownItem>[];
    groups.forEach((key, value) {
      if (key != 'all' && value is List) {
        results.add(BreakdownItem.fromTimeseriesGroup(key, value));
      }
    });
    
    results.sort((a, b) => b.visitors.compareTo(a.visitors));
    return results;
  }

  // ==================== DEPLOYMENT ACTIONS ====================

  /// Promote a deployment to production
  /// [projectId] - The project ID
  /// [deploymentId] - The deployment ID to promote
  Future<Map<String, dynamic>> promoteDeployment({
    required String projectId,
    required String deploymentId,
  }) async {
    final response = await http.post(
      _buildUri('/v13/deployments/$deploymentId/promote'),
      headers: await _getHeaders(),
      body: json.encode({'target': 'production'}),
    );
    return await _handleResponse(response);
  }

  /// Rollback to a previous deployment
  /// [projectId] - The project ID
  /// [deploymentId] - The deployment ID to rollback to
  Future<Map<String, dynamic>> rollbackDeployment({
    required String projectId,
    required String deploymentId,
  }) async {
    final response = await http.post(
      _buildUri('/v13/deployments/$deploymentId/rollback'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  /// Cancel an ongoing deployment
  /// [projectId] - The project ID
  /// [deploymentId] - The deployment ID to cancel
  Future<Map<String, dynamic>> cancelDeployment({
    required String projectId,
    required String deploymentId,
  }) async {
    final response = await http.patch(
      _buildUri('/v13/deployments/$deploymentId/cancel'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // ==================== LOGS & OBSERVABILITY ====================

  /// Get runtime logs for a deployment
  /// 
  /// IMPORTANT: This endpoint streams LIVE logs only and waits for new entries.
  /// It does NOT return historical logs. If no logs are currently being generated,
  /// the request will timeout after the specified duration.
  /// 
  /// For historical build logs, use [getDeploymentEvents] or [getDeploymentBuildLogs].
  /// 
  /// [projectId] - The project ID
  /// [deploymentId] - The deployment ID
  /// [limit] - Maximum number of log entries to return
  /// [since] - Timestamp to get logs since (milliseconds)
  /// [until] - Timestamp to get logs until (milliseconds)
  /// [timeoutSeconds] - How long to wait for logs (default: 5 seconds for UX)
  Future<List<Map<String, dynamic>>> getDeploymentRuntimeLogs({
    required String projectId,
    required String deploymentId,
    int? limit,
    int? since,
    int? until,
    int timeoutSeconds = 5,
  }) async {
    if (kDebugMode) {
      print('[VercelApi] getDeploymentRuntimeLogs called');
      print('[VercelApi]   projectId: $projectId');
      print('[VercelApi]   deploymentId: $deploymentId');
      print('[VercelApi]   teamId: $teamId');
      print('[VercelApi]   timeout: ${timeoutSeconds}s (LIVE logs only)');
    }
    
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (since != null) params['since'] = since.toString();
    if (until != null) params['until'] = until.toString();

    final uri = _buildUri('/v1/projects/$projectId/deployments/$deploymentId/runtime-logs', params.isNotEmpty ? params : null);
    if (kDebugMode) print('[VercelApi]   Request URL: $uri');

    final client = http.Client();
    final maxEntries = limit ?? 100;
    try {
      final headers = await _getHeaders();
      final request = http.Request('GET', uri);
      request.headers.addAll(headers);

      final streamedResponse = await client.send(request).timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          if (kDebugMode) print('[VercelApi]   Request timed out after $timeoutSeconds seconds - no live logs available');
          throw TimeoutException('No live runtime logs available. The deployment may not be receiving traffic.', Duration(seconds: timeoutSeconds));
        },
      );

      if (kDebugMode) print('[VercelApi]   Response status: ${streamedResponse.statusCode}');
      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        if (kDebugMode) print('[VercelApi]   Response body: $body');
        final data = await _handleResponse(http.Response(body, streamedResponse.statusCode));
        final logs = data['logs'] as List<dynamic>? ?? [];
        if (kDebugMode) print('[VercelApi]   Logs count: ${logs.length}');
        return logs.cast<Map<String, dynamic>>();
      }

      final lineStream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      final iterator = StreamIterator<String>(lineStream);
      final logs = <Map<String, dynamic>>[];

      try {
        // Use a shorter timeout for collecting logs to improve UX
        final collectStart = DateTime.now();
        final collectTimeout = Duration(seconds: timeoutSeconds);
        
        while (await iterator.moveNext().timeout(
          collectTimeout,
          onTimeout: () {
            if (kDebugMode) print('[VercelApi]   Collection timeout - returning ${logs.length} logs collected so far');
            return false;
          },
        )) {
          final line = iterator.current.trim();
          if (line.isEmpty) continue;
          try {
            final decoded = jsonDecode(line);
            if (decoded is Map<String, dynamic>) {
              logs.add(decoded);
            } else {
              logs.add(_wrapLogLine(line));
            }
          } catch (e) {
            logs.add(_wrapLogLine(line));
          }

          if (logs.length >= maxEntries) {
            await iterator.cancel();
            break;
          }
          
          // Check if we've exceeded our collection timeout
          if (DateTime.now().difference(collectStart) > collectTimeout) {
            if (kDebugMode) print('[VercelApi]   Collection time limit reached - returning ${logs.length} logs');
            break;
          }
        }
      } finally {
        await iterator.cancel();
      }

      if (kDebugMode) print('[VercelApi]   Lines collected: ${logs.length}');
      return logs;
    } on TimeoutException {
      if (kDebugMode) print('[VercelApi]   No live logs available (timeout)');
      // Return empty list for timeout - this is expected behavior for deployments without traffic
      return [];
    } catch (e) {
      if (kDebugMode) print('[VercelApi]   Error in getDeploymentRuntimeLogs: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Get function logs for a deployment
  /// 
  /// DEPRECATED: The function-logs endpoint does not exist in the Vercel API.
  /// Use [getDeploymentRuntimeLogs] with filtering instead.
  /// 
  /// [projectId] - The project ID
  /// [deploymentId] - The deployment ID
  /// [functionName] - Optional specific function name to filter (not implemented)
  /// [limit] - Maximum number of log entries
  @deprecated
  Future<List<Map<String, dynamic>>> getDeploymentFunctionLogs({
    required String projectId,
    required String deploymentId,
    String? functionName,
    int? limit,
  }) async {
    if (kDebugMode) {
      print('[VercelApi] WARNING: getDeploymentFunctionLogs is deprecated');
      print('[VercelApi] Use getDeploymentRuntimeLogs instead');
    }
    // Delegate to runtime logs and filter by function name if provided
    final logs = await getDeploymentRuntimeLogs(
      projectId: projectId,
      deploymentId: deploymentId,
      limit: limit,
      timeoutSeconds: 3, // Short timeout since this is deprecated
    );
    if (functionName != null) {
      return logs.where((log) {
        final message = log['message']?.toString().toLowerCase() ?? '';
        return message.contains(functionName.toLowerCase());
      }).toList();
    }
    return logs;
  }

  /// Get request logs for a deployment
  /// 
  /// DEPRECATED: Use [getDeploymentRuntimeLogs] instead. This endpoint does not
  /// support simple GET requests - it requires streaming.
  /// 
  /// [projectId] - The project ID
  /// [deploymentId] - The deployment ID
  /// [limit] - Maximum number of log entries
  /// [since] - Timestamp to get logs since (milliseconds)
  @deprecated
  Future<List<Map<String, dynamic>>> getDeploymentRequestLogs({
    required String projectId,
    required String deploymentId,
    int? limit,
    int? since,
  }) async {
    if (kDebugMode) {
      print('[VercelApi] WARNING: getDeploymentRequestLogs is deprecated');
      print('[VercelApi] Use getDeploymentRuntimeLogs instead');
    }
    // Delegate to the streaming runtime logs endpoint
    return getDeploymentRuntimeLogs(
      projectId: projectId,
      deploymentId: deploymentId,
      limit: limit,
      since: since,
      timeoutSeconds: 3, // Short timeout for UX
    );
  }

  /// Get domain configuration including DNS details
  /// [domain] - The domain name
  Future<Map<String, dynamic>> getDomainConfiguration(String domain) async {
    try {
      final response = await http.get(
        _buildUri('/v6/domains/$domain/config'),
        headers: await _getHeaders(),
      );
      return await _handleResponse(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getDomainConfiguration for domain "$domain": $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Get deployment-specific domains
  /// DEPRECATED: This endpoint is not available in the Vercel API.
  /// Use [getProjectDomains] to get domains for a project instead.
  /// [projectId] - The project ID
  /// [deploymentId] - The deployment ID
  @deprecated
  Future<List<Map<String, dynamic>>> getDeploymentDomains({
    required String projectId,
    required String deploymentId,
  }) async {
    // This endpoint doesn't exist in Vercel API - return empty list
    if (kDebugMode) {
      print('[VercelApi] WARNING: getDeploymentDomains is deprecated and returns empty list');
      print('[VercelApi] Use getProjectDomains(projectId) instead');
    }
    return [];
  }

  /// Get build logs for a deployment
  /// Uses the v3/events endpoint which provides build events and logs
  /// [projectId] - The project ID
  /// [deploymentId] - The deployment ID
  Future<List<Map<String, dynamic>>> getDeploymentBuildLogs({
    required String projectId,
    required String deploymentId,
  }) async {
    // Build logs are available through the deployment events endpoint
    final events = await getDeploymentEvents(deploymentId);
    // Filter for build-related events (delimiter, build-related)
    return events.where((event) {
      final type = event['type'] as String? ?? '';
      final text = event['text'] as String? ?? '';
      // Include delimiter events and build-related events
      return type == 'delimiter' ||
             text.toLowerCase().contains('build') ||
             text.toLowerCase().contains('compil') ||
             text.toLowerCase().contains('install');
    }).cast<Map<String, dynamic>>().toList();
  }

  /// List deployment files - DEPRECATED: Use getDeploymentFileTree instead
  /// [deploymentId] - The deployment ID
  /// 
  /// NOTE: This method uses the old /v6/deployments/{id}/files endpoint which
  /// returns 404 for many deployments. Use getDeploymentFileTree() with the
  /// deployment URL for reliable file fetching (competitor approach).
  @deprecated
  Future<List<DeploymentFile>> getDeploymentFiles(String deploymentId) async {
    if (kDebugMode) {
      print('[VercelApi] getDeploymentFiles called');
      print('[VercelApi]   deploymentId: $deploymentId');
      print('[VercelApi]   teamId: $teamId');
    }
    
    final params = <String, String>{};
    if (teamId != null) params['teamId'] = teamId!;

    final uri = _buildUri('/v6/deployments/$deploymentId/files', params);
    if (kDebugMode) print('[VercelApi]   Request URL: $uri');

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    
    if (kDebugMode) {
      print('[VercelApi]   Response status: ${response.statusCode}');
      print('[VercelApi]   Response body length: ${response.body.length}');
      if (response.statusCode != 200) {
        print('[VercelApi]   Response body: ${response.body}');
      }
    }
    
    // Handle 404 gracefully for Git deployments (no file tree)
    if (response.statusCode == 404) {
      if (kDebugMode) print('[VercelApi] File tree not found (likely Git deployment) - returning empty list');
      return [];
    }
    
    final data = await _handleResponse(response);
    final list = data as List<dynamic>? ?? [];
    if (kDebugMode) {
      print('[VercelApi]   Files count: ${list.length}');
      print('[VercelApi] getDeploymentFiles completed');
    }
    
    return list.map((json) => DeploymentFile.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get deployment file tree using the file-tree endpoint (competitor approach)
  /// 
  /// This endpoint uses the deployment URL instead of ID and returns a hierarchical
  /// file structure with 'link' fields for fetching file contents.
  /// 
  /// [deploymentUrl] - The deployment URL (e.g., 'my-app.vercel.app')
  /// [base] - The base directory to fetch ('src' for source, 'out' for output)
  Future<List<DeploymentFile>> getDeploymentFileTree({
    required String deploymentUrl,
    String base = 'src',
  }) async {
    if (kDebugMode) {
      print('[VercelApi] getDeploymentFileTree called');
      print('[VercelApi]   deploymentUrl: $deploymentUrl');
      print('[VercelApi]   base: $base');
      print('[VercelApi]   teamId: $teamId');
    }
    
    final params = <String, String>{
      'base': base,
    };
    if (teamId != null) params['teamId'] = teamId!;

    final uri = _buildUri('/file-tree/$deploymentUrl', params);
    if (kDebugMode) print('[VercelApi]   Request URL: $uri');

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    
    if (kDebugMode) {
      print('[VercelApi]   Response status: ${response.statusCode}');
      print('[VercelApi]   Response body length: ${response.body.length}');
    }
    
    // Handle 404 gracefully for Git deployments (no file tree)
    if (response.statusCode == 404) {
      if (kDebugMode) print('[VercelApi] File tree not found (likely Git deployment) - returning empty list');
      return [];
    }
    
    final data = await _handleResponse(response);
    final list = data as List<dynamic>? ?? [];
    if (kDebugMode) {
      print('[VercelApi]   Files count: ${list.length}');
      print('[VercelApi] getDeploymentFileTree completed');
    }
    
    return list.map((json) => DeploymentFile.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get deployment file contents
  /// [deploymentId] - The deployment ID
  /// [fileId] - The file ID (uid)
  Future<String> getDeploymentFileContents(String deploymentId, String fileId) async {
    if (kDebugMode) {
      print('[VercelApi] getDeploymentFileContents called');
      print('[VercelApi]   deploymentId: $deploymentId');
      print('[VercelApi]   fileId: $fileId');
      print('[VercelApi]   teamId: $teamId');
    }
    
    final params = <String, String>{};
    if (teamId != null) params['teamId'] = teamId!;

    final uri = _buildUri('/v8/deployments/$deploymentId/files/$fileId', params);
    if (kDebugMode) print('[VercelApi]   Request URL: $uri');

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    
    if (kDebugMode) {
      print('[VercelApi]   Response status: ${response.statusCode}');
      print('[VercelApi]   Response body length: ${response.body.length}');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // The response body contains the file content encoded as base64
      try {
        final data = json.decode(response.body);
        if (kDebugMode) print('[VercelApi]   Response parsed as JSON');
        if (data is Map) {
          // API can return either 'content' or 'data' field with base64
          String? base64Content = data['content'] as String?;
          base64Content ??= data['data'] as String?;
          
          if (base64Content != null) {
            if (kDebugMode) print('[VercelApi]   Found base64 field (${data.containsKey('content') ? 'content' : 'data'}), decoding...');
            return utf8.decode(base64.decode(base64Content));
          }
        }
        // Fallback: try to decode the entire response as base64
        if (kDebugMode) print('[VercelApi]   No content/data field, trying base64 decode of entire body');
        return utf8.decode(base64.decode(response.body));
      } catch (e) {
        // If decoding fails, return the raw response
        if (kDebugMode) print('[VercelApi]   Decoding failed, returning raw response: $e');
        return response.body;
      }
    } else {
      if (kDebugMode) print('[VercelApi]   Error response body: ${response.body}');
      throw VercelApiException('Failed to get file contents', statusCode: response.statusCode);
    }
  }

  /// Fetch file content from a direct URL (used by file-tree API)
  /// [fileUrl] - The full URL to fetch the file from (includes token)
  Future<String> fetchFileFromUrl(String fileUrl) async {
    if (kDebugMode) {
      print('[VercelApi] fetchFileFromUrl called');
      print('[VercelApi]   fileUrl: $fileUrl');
    }
    
    final response = await http.get(
      Uri.parse(fileUrl),
      headers: await _getHeaders(),
    );
    
    if (kDebugMode) {
      print('[VercelApi]   Response status: ${response.statusCode}');
      print('[VercelApi]   Response body length: ${response.body.length}');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Try to decode as base64 first
      try {
        final data = json.decode(response.body);
        if (data is Map) {
          // API can return either 'content' or 'data' field with base64
          String? base64Content = data['content'] as String?;
          base64Content ??= data['data'] as String?;
          
          if (base64Content != null) {
            if (kDebugMode) print('[VercelApi]   Found base64 field (${data.containsKey('content') ? 'content' : 'data'}), decoding...');
            return utf8.decode(base64.decode(base64Content));
          }
        }
        // If it's JSON but no content/data field, return raw body
        return response.body;
      } catch (e) {
        // Not JSON or decoding failed, return raw response
        if (kDebugMode) print('[VercelApi]   Returning raw response');
        return response.body;
      }
    } else {
      if (kDebugMode) print('[VercelApi]   Error response body: ${response.body}');
      throw VercelApiException('Failed to fetch file from URL', statusCode: response.statusCode);
    }
  }

  /// Get project logs using the /logs/request-logs endpoint (Revcel approach)
  /// 
  /// This endpoint returns historical logs with pagination and filtering support.
  /// Unlike the streaming runtime-logs endpoint, this can retrieve logs from any time period.
  /// 
  /// [projectId] - The project ID to fetch logs for
  /// [ownerId] - Required - team ID or user ID (from AppState.user['id'])
  /// [deploymentId] - Optional deployment ID to filter logs
  /// [startDate] - Start timestamp as string. Use '1' for max fetch (competitor approach) or milliseconds timestamp
  /// [endDate] - End timestamp as string in milliseconds (optional)
  /// [page] - Page number for pagination
  /// [attributes] - Filter attributes (host, method, statusCode, etc.)
  /// [limit] - Not directly supported by this endpoint (use pagination instead)
  Future<ProjectLogsResult> getProjectLogs({
    required String projectId,
    required String ownerId,
    String? deploymentId,
    String? startDate, // Can be '1' for max fetch or milliseconds timestamp
    String? endDate, // Milliseconds timestamp (optional)
    int? page,
    Map<String, List<String>>? attributes,
  }) async {
    print('[VercelApi] getProjectLogs called');
    print('[VercelApi]   projectId: $projectId');
    print('[VercelApi]   ownerId: $ownerId');
    print('[VercelApi]   deploymentId: $deploymentId');
    print('[VercelApi]   teamId: $teamId');

    // Default to '1' which fetches maximum allowed logs (competitor approach)
    final effectiveStartDate = startDate ?? '1';

    final params = <String, String>{
      'projectId': projectId,
      'ownerId': ownerId,
      'startDate': effectiveStartDate,
    };

    if (deploymentId != null) {
      params['deploymentId'] = deploymentId;
    }

    if (page != null && page > 0) {
      params['page'] = page.toString();
    }

    // Add filter attributes
    if (attributes != null) {
      for (final entry in attributes.entries) {
        if (entry.value.isNotEmpty) {
          params[entry.key] = entry.value.join(',');
        }
      }
    }

    final uri = _buildUri('/logs/request-logs', params);
    print('[VercelApi]   Request URL: $uri');

    try {
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      print('[VercelApi]   Response status: ${response.statusCode}');

      final data = await _handleResponse(response);
      final rows = data['rows'] as List<dynamic>? ?? [];
      final hasMoreRows = data['hasMoreRows'] as bool? ?? false;

      print('[VercelApi]   Logs count: ${rows.length}, hasMoreRows: $hasMoreRows');

      return ProjectLogsResult(
        logs: rows.map((json) => Log.fromJson(json as Map<String, dynamic>)).toList(),
        hasMoreRows: hasMoreRows,
        nextPage: hasMoreRows ? (page ?? 0) + 1 : null,
      );
    } catch (e) {
      print('[VercelApi]   Error in getProjectLogs: $e');
      rethrow;
    }
  }

  /// Get available filter values for project logs
  /// 
  /// Fetches distinct values for specific filter attributes (host, method, statusCode, etc.)
  /// Useful for populating filter dropdowns.
  /// 
  /// [projectId] - The project ID
  /// [attributes] - List of attribute names to fetch values for
  /// [startDate] - Start date as Unix timestamp string (default: '1' for max fetch)
  /// [endDate] - End date as Unix timestamp string (optional)
  Future<Map<String, List<LogFilterValue>>> getProjectLogsFilters({
    required String projectId,
    required List<String> attributes,
    String? startDate, // Unix timestamp as string (default: '1')
    String? endDate, // Unix timestamp as string
  }) async {
    print('[VercelApi] getProjectLogsFilters called');
    print('[VercelApi]   projectId: $projectId');
    print('[VercelApi]   attributes: $attributes');

    // ownerId (teamId) is REQUIRED for this endpoint
    if (teamId == null) {
      throw VercelApiException('Team ID not set. Please call fetchUserInfoAndSetTeamId() after authentication to automatically retrieve and set your team ID.');
    }

    // Default to '1' for max fetch like competitor
    final effectiveStartDate = startDate ?? '1';

    final baseParams = <String, String>{
      'ownerId': teamId!, // Required parameter
      'projectId': projectId,
      'startDate': effectiveStartDate,
    };
    
    if (endDate != null) {
      baseParams['endDate'] = endDate;
    }

    final results = <String, List<LogFilterValue>>{};

    // Fetch each attribute with a small delay to avoid rate limiting (like Revcel does)
    for (int i = 0; i < attributes.length; i++) {
      final attribute = attributes[i];
      
      // Add staggered delay (50ms between requests)
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final params = Map<String, String>.from(baseParams);
      params['attributeName'] = attribute;

      final uri = _buildUri('/logs/request-logs/filter-values', params);
      print('[VercelApi]   Fetching filter values for $attribute');

      try {
        final response = await http.get(
          uri,
          headers: await _getHeaders(),
        );

        final data = await _handleResponse(response);
        final rows = data['rows'] as List<dynamic>? ?? [];

        results[attribute] = rows
            .map((json) => LogFilterValue.fromJson(json as Map<String, dynamic>))
            .toList();

        print('[VercelApi]   Found ${results[attribute]?.length} values for $attribute');
      } catch (e) {
        print('[VercelApi]   Error fetching filter values for $attribute: $e');
        results[attribute] = [];
      }
    }

    return results;
  }

  // Regex for extracting favicon href from HTML
  // Matches: <link rel="icon" href="..."> or <link rel='icon' href='...'>
  static final RegExp _linkIconHrefRegex = RegExp(
    r'<link[^>]*rel=[\x27\x22][^\x27\x22]*(?:icon|shortcut icon|apple-touch-icon)[^\x27\x22]*[\x27\x22][^>]*href=[\x27\x22]([^\x27\x22]+)[\x27\x22][^>]*>',
    caseSensitive: false,
  );

  static final RegExp _trailingSlashesRegex = RegExp(r'/+$');
  static final RegExp _absoluteUrlRegex = RegExp(r'^https?://', caseSensitive: false);

  /// Fetch project favicon using the same approach as Revcel:
  /// 1. Try Vercel's deployment favicon API endpoint
  /// 2. Fall back to common favicon paths on the deployment URL
  /// 3. Parse HTML for link rel="icon" tags as last resort
  /// 
  /// [projectId] - The project ID to fetch favicon for
  /// Returns the favicon URL string, or null if not found
  Future<String?> getProjectFavicon(String projectId) async {
    print('[VercelApi] getProjectFavicon called for project: $projectId');

    try {
      // Fetch the most recent READY deployment for this project
      final deployments = await getDeployments(projectId: projectId);
      final readyDeployment = deployments
          .where((d) => d.state == 'READY')
          .firstOrNull;

      if (readyDeployment == null) {
        print('[VercelApi] No READY deployment found for project: $projectId');
        return null;
      }

      final deploymentId = readyDeployment.uid;
      final deploymentHost = readyDeployment.url;

      print('[VercelApi] Using deployment: $deploymentId (host: $deploymentHost)');

      // First attempt: Vercel deployment favicon endpoint
      final faviconUrl = await _fetchVercelDeploymentFavicon(deploymentId);
      if (faviconUrl != null) {
        print('[VercelApi] Found favicon via Vercel API: $faviconUrl');
        return faviconUrl;
      }

      // Fallback: try to resolve favicon from the website itself
      if (deploymentHost.isNotEmpty) {
        final websiteFavicon = await _resolveWebsiteFavicon('https://$deploymentHost');
        if (websiteFavicon != null) {
          print('[VercelApi] Found favicon via website fallback: $websiteFavicon');
          return websiteFavicon;
        }
      }

      print('[VercelApi] No favicon found for project: $projectId');
      return null;
    } catch (e, stackTrace) {
      print('[VercelApi] Error fetching favicon for project $projectId: $e');
      print('[VercelApi] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Try to fetch favicon from Vercel's deployment favicon endpoint
  /// Following the competitor's approach: follow redirects and return the final URL
  Future<String?> _fetchVercelDeploymentFavicon(String deploymentId) async {
    try {
      final params = <String, String>{};
      if (teamId != null) params['teamId'] = teamId!;

      final uri = _buildUri('/v0/deployments/$deploymentId/favicon', params);
      print('[VercelApi] Trying Vercel favicon endpoint: $uri');

      final token = await _authService.getToken();
      if (token == null) return null;

      // Create a client that follows redirects manually so we can capture the final URL
      final client = http.Client();
      try {
        final request = http.Request('GET', uri);
        request.headers['Authorization'] = 'Bearer $token';

        final streamedResponse = await client.send(request);
        print('[VercelApi] Favicon initial response: ${streamedResponse.statusCode}');

        // The Vercel API returns 302 redirect to the actual favicon URL
        // We need to follow the redirect chain to get the final URL
        Uri currentUri = uri;
        int redirectCount = 0;
        const maxRedirects = 5;

        while ((streamedResponse.statusCode == 301 ||
                streamedResponse.statusCode == 302 ||
                streamedResponse.statusCode == 307 ||
                streamedResponse.statusCode == 308) &&
            redirectCount < maxRedirects) {
          final location = streamedResponse.headers['location'];
          if (location == null || location.isEmpty) break;

          // Resolve relative URLs
          final newUri = location.startsWith('http')
              ? Uri.parse(location)
              : currentUri.resolve(location);
          print('[VercelApi] Following redirect to: $newUri');

          // Cancel the current response stream
          await streamedResponse.stream.drain();

          // Make the new request
          final newRequest = http.Request('GET', newUri);
          newRequest.headers['Authorization'] = 'Bearer $token';
          final newResponse = await client.send(newRequest);

          currentUri = newUri;
          redirectCount++;

          // If this is not another redirect, we're done
          if (newResponse.statusCode != 301 &&
              newResponse.statusCode != 302 &&
              newResponse.statusCode != 307 &&
              newResponse.statusCode != 308) {
            // Success - return the final URL
            if (newResponse.statusCode == 200) {
              print('[VercelApi] Found favicon at final URL: $currentUri');
              await newResponse.stream.drain(); // Clean up
              return currentUri.toString();
            }
            break;
          }
        }

        // If we got a 200 directly (no redirects), check if it's an image
        if (streamedResponse.statusCode == 200) {
          final contentType = streamedResponse.headers['content-type'];
          if (contentType != null && contentType.startsWith('image/')) {
            // Return the final URL - the image can be loaded from this URL
            print('[VercelApi] Found favicon at: $currentUri');
            await streamedResponse.stream.drain(); // Clean up
            return currentUri.toString();
          }
        }

        // Clean up the response stream
        await streamedResponse.stream.drain();
      } finally {
        client.close();
      }

      print('[VercelApi] Vercel favicon endpoint did not return a valid image');
      return null;
    } catch (e) {
      print('[VercelApi] Error fetching Vercel deployment favicon: $e');
      return null;
    }
  }

  /// Fallback: resolve favicon from the website by checking common paths
  Future<String?> _resolveWebsiteFavicon(String siteBaseUrl) async {
    final base = siteBaseUrl.replaceAll(_trailingSlashesRegex, '');
    final candidatePaths = [
      '/favicon.ico',
      '/favicon.png',
      '/favicon.svg',
      '/apple-touch-icon.png',
      '/apple-touch-icon-precomposed.png',
    ];

    // Try each candidate path
    for (final path in candidatePaths) {
      final url = '$base$path';
      try {
        final response = await http.get(Uri.parse(url));
        final contentType = response.headers['content-type'] ?? '';

        if (response.statusCode == 200 &&
            (contentType.startsWith('image/') ||
                path.endsWith('.ico') ||
                path.endsWith('.png') ||
                path.endsWith('.svg'))) {
          print('[VercelApi] Found favicon at: $url');
          return url;
        }
      } catch (_) {
        // Ignore and try next candidate
      }
    }

    // Last resort: try parsing the homepage HTML for a link rel="icon" tag
    try {
      final homeResponse = await http.get(Uri.parse(base));
      if (homeResponse.statusCode == 200) {
        final html = homeResponse.body;
        final href = _extractIconHrefFromHtml(html);
        if (href != null) {
          // Resolve relative URLs
          String resolvedUrl;
          if (_absoluteUrlRegex.hasMatch(href)) {
            resolvedUrl = href;
          } else if (href.startsWith('/')) {
            resolvedUrl = '$base$href';
          } else {
            resolvedUrl = '$base/$href';
          }
          print('[VercelApi] Found favicon via HTML parsing: $resolvedUrl');
          return resolvedUrl;
        }
      }
    } catch (_) {
      // Ignore
    }

    return null;
  }

  /// Extract favicon href from HTML using regex
  String? _extractIconHrefFromHtml(String html) {
    final match = _linkIconHrefRegex.firstMatch(html);
    return match?.group(1);
  }
}

