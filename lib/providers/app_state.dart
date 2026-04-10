import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/superwall_service.dart';
import '../models/project.dart';
import 'subscription_provider.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SuperwallService _superwallService = SuperwallService();
  VercelApi _apiService = VercelApi();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;
  String? _errorMessage;
  
  List<Project> _projects = [];
  Project? _selectedProject;
  Map<String, dynamic>? _user;
  List<dynamic> _teams = [];
  String? _currentTeamId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get errorMessage => _errorMessage;
  List<Project> get projects => _projects;
  Project? get selectedProject => _selectedProject;
  Map<String, dynamic>? get user => _user;
  List<dynamic> get teams => _teams;
  String? get currentTeamId => _currentTeamId;
  VercelApi get apiService => _apiService;

  void setSelectedProject(Project? project) {
    _selectedProject = project;
    notifyListeners();
  }

  AppState() {
    _checkAuth();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
    notifyListeners();
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', false);
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  Future<void> _checkAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      _isAuthenticated = await _authService.isAuthenticated();
      if (_isAuthenticated) {
        await fetchInitialData();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchTeam(String? teamId) async {
    final previousTeamId = _currentTeamId;
    _currentTeamId = teamId;
    _apiService = VercelApi(teamId: teamId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    // Track team switch
    await _superwallService.trackUserAction('switch_team', context: 'app_state', properties: {
      'from_team': previousTeamId ?? 'personal',
      'to_team': teamId ?? 'personal',
    });
    
    try {
      await fetchProjects();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.saveToken(token);
      _isAuthenticated = true;
      await fetchInitialData();
      
      // Sync login with Superwall using user ID
      if (_user != null && _user!['id'] != null) {
        final userId = _user!['id'].toString();
        await _superwallService.identify(userId);
        
        // Set user attributes for analytics segmentation
        await _superwallService.setUserAttributes({
          'user_id': userId,
          'username': _user!['username'] ?? '',
          'email': _user!['email'] ?? '',
          'plan': _user!['plan'] ?? 'free',
          'project_count': _projects.length,
          'team_count': _teams.length,
          'has_pro': _user!['plan'] == 'pro',
        });
        
        // Track successful login
        await _superwallService.trackUserAction('login_success', context: 'app_state');
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithOAuth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final oauthResponse = await _authService.loginWithVercel();
      _isAuthenticated = true;

      // Extract user info from JWT id_token
      final idToken = oauthResponse['id_token'] as String?;
      if (idToken != null) {
        _user = _decodeJwt(idToken);
      }

      // Try to fetch initial data (may fail if OAuth token doesn't have API access)
      try {
        await fetchInitialData(skipLogoutOn404: true);
      } catch (e) {
        // Don't fail login - user is authenticated via OAuth
      }

      // Sync login with Superwall using user ID from JWT
      if (_user != null) {
        final userId = _user!['sub']?.toString() ?? _user!['preferred_username']?.toString();
        if (userId != null) {
          await _superwallService.identify(userId);

          // Set user attributes for analytics segmentation
          await _superwallService.setUserAttributes({
            'user_id': userId,
            'username': _user!['preferred_username'] ?? '',
            'email': _user!['email'] ?? '',
            'plan': _user!['plan'] ?? 'free',
            'project_count': _projects.length,
            'team_count': _teams.length,
            'has_pro': _user!['plan'] == 'pro',
          });

          // Track successful OAuth login
          await _superwallService.trackUserAction('oauth_login_success', context: 'app_state');
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      // Don't automatically logout - let the user see the error
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT token');
    }

    final payload = parts[1];
    // Add padding if needed
    final normalized = base64.normalize(payload);
    final decoded = base64.decode(normalized);
    final jsonString = utf8.decode(decoded);
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  Future<void> logout({SubscriptionProvider? subscriptionProvider}) async {
    // Track logout before resetting
    await _superwallService.trackUserAction('logout', context: 'app_state');
    
    // Sync logout with Superwall
    try {
      await _superwallService.reset();
    } catch (e) {
      if (kDebugMode) print('Superwall logout error: $e');
    }
    
    // Reset subscription state if provider is available
    if (subscriptionProvider != null) {
      try {
        await subscriptionProvider.onUserLogout();
      } catch (e) {
        if (kDebugMode) print('SubscriptionProvider logout error: $e');
      }
    }
    
    await _authService.deleteToken();
    _isAuthenticated = false;
    _projects = [];
    _selectedProject = null;
    _user = null;
    _teams = [];
    _currentTeamId = null;
    _apiService = VercelApi();
    notifyListeners();
  }

  Future<void> fetchInitialData({bool skipLogoutOn404 = false}) async {
    _errorMessage = null;
    try {
      // Fetch user and teams first
      _user = await _apiService.getUser();
      await fetchTeams();
      await fetchProjects();
    } on VercelApiException catch (e) {
      // If user not found (404), token is likely invalid/expired
      if (e.statusCode == 404) {
        if (!skipLogoutOn404) {
          await logout();
          _errorMessage = 'Session expired. Please log in again.';
        } else {
          _errorMessage = 'Could not fetch user data (OAuth token may not have API access)';
        }
      } else {
        _errorMessage = e.toString();
      }
      if (kDebugMode) print('Error fetching initial data: $e');
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) print('Error fetching initial data: $e');
    }
    notifyListeners();
  }

  Future<void> fetchTeams() async {
    try {
      final response = await _apiService.getTeams();
      _teams = response['teams'] as List<dynamic>? ?? [];
    } catch (e) {
      if (kDebugMode) print('Error fetching teams: $e');
    }
  }

  Future<void> disconnectFromVercel() async {
    await _authService.deleteToken();
    _projects = [];
    _selectedProject = null;
    _teams = [];
    _currentTeamId = null;
    _apiService = VercelApi();
    notifyListeners();
  }

  Future<void> fetchProjects() async {
    try {
      _projects = await _apiService.getProjectsList();
      if (_projects.isNotEmpty) {
        _selectedProject = _projects.first;
      } else {
        _selectedProject = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }
}
