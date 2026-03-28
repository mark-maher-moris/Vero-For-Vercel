import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/deployment.dart';
import 'auth_service.dart';

class VercelApi {
  static const String baseUrl = 'https://api.vercel.com';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No access token found');
    return {
      'Authorization': 'Bearer \$token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getUser() async {
    final response = await http.get(
      Uri.parse('\$baseUrl/v2/user'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user info');
    }
  }

  Future<List<Project>> getProjects() async {
    final response = await http.get(
      Uri.parse('\$baseUrl/v9/projects'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List projectsJson = data['projects'] as List;
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load projects');
    }
  }

  Future<List<Deployment>> getDeployments({String? projectId}) async {
    final uriStr = '\$baseUrl/v6/deployments\${projectId != null ? "?projectId=\$projectId" : ""}';
    final uri = Uri.parse(uriStr);
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List deploymentsJson = data['deployments'] as List;
      return deploymentsJson.map((json) => Deployment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load deployments');
    }
  }

  Future<List<dynamic>> getProjectEnvVars(String projectId) async {
    final response = await http.get(
      Uri.parse('\$baseUrl/v9/projects/\$projectId/env'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['envs'] as List<dynamic>? ?? [];
    } else {
      throw Exception('Failed to load environment variables');
    }
  }

  Future<List<dynamic>> getProjectDomains(String projectId) async {
    final response = await http.get(
      Uri.parse('\$baseUrl/v9/projects/\$projectId/domains'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['domains'] as List<dynamic>? ?? [];
    } else {
      throw Exception('Failed to load domains');
    }
  }

  Future<List<dynamic>> getDeploymentEvents(String deploymentId) async {
    final response = await http.get(
      Uri.parse('\$baseUrl/v2/deployments/\$deploymentId/events'),
      headers: await _getHeaders(),
    );
    
    // Vercel deployment events stream returns JSON lines or an array based on headers/version.
    // For simplicity, assuming a standard array or parsing lines if it's text.
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data is List) return data;
        return [data];
      } catch (e) {
        // It might be NDJSON (Newline Delimited JSON)
        final lines = response.body.split('\n').where((l) => l.trim().isNotEmpty);
        return lines.map((l) => json.decode(l)).toList();
      }
    } else {
      throw Exception('Failed to load deployment logs');
    }
  }
}
