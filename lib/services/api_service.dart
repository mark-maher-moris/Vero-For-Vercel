import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/deployment.dart';
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
    
    final queryString = params.isNotEmpty 
        ? '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&')
        : '';
        
    return Uri.parse('$baseUrl$path$queryString');
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

  Future<Map<String, dynamic>> getUser() async {
    final response = await http.get(
      _buildUri('/v2/user'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<List<Project>> getProjects() async {
    final response = await http.get(
      _buildUri('/v9/projects'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    final List projectsJson = data['projects'] as List;
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
      _buildUri('/v2/deployments/$deploymentId/events'),
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
}
