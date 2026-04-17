import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
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
  
  // Favicon cache: projectId -> faviconUrl
  final Map<String, String?> _faviconCache = {};
  
  // In-flight favicon requests for deduplication: projectId -> Future
  final Map<String, Future<String?>> _faviconInFlightRequests = {};

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
  Map<String, String?> get faviconCache => _faviconCache;

  /// Get cached favicon for a project, or fetch and cache it if not available.
  /// Uses request deduplication to prevent multiple simultaneous API calls for the same project.
  Future<String?> getCachedFavicon(String projectId) async {
    // Return cached value if available (including null for "no favicon")
    if (_faviconCache.containsKey(projectId)) {
      return _faviconCache[projectId];
    }

    // If a request is already in-flight for this project, return the same Future
    if (_faviconInFlightRequests.containsKey(projectId)) {
      return _faviconInFlightRequests[projectId];
    }

    // Create the fetch future and track it
    final fetchFuture = _fetchAndCacheFavicon(projectId);
    _faviconInFlightRequests[projectId] = fetchFuture;

    // Clean up the in-flight tracking when done
    fetchFuture.then((_) {
      _faviconInFlightRequests.remove(projectId);
    }).catchError((_) {
      _faviconInFlightRequests.remove(projectId);
    });

    return fetchFuture;
  }

  /// Internal method to fetch favicon and cache the result
  Future<String?> _fetchAndCacheFavicon(String projectId) async {
    try {
      final favicon = await _apiService.getProjectFavicon(projectId);
      _faviconCache[projectId] = favicon;
      return favicon;
    } catch (e) {
      // Cache the null result on error to prevent repeated failed requests
      _faviconCache[projectId] = null;
      return null;
    }
  }

  /// Clear favicon cache (e.g., on logout or team switch)
  void clearFaviconCache() {
    _faviconCache.clear();
    _faviconInFlightRequests.clear();
  }

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
    // Clear favicon cache when switching teams (different projects)
    clearFaviconCache();
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
    if (kDebugMode) print('[AppState] Login started');
    try {
      // Validate token before saving
      if (kDebugMode) print('[AppState] Validating token...');
      final isValid = await _authService.validateToken(token);
      if (!isValid) {
        throw Exception('Invalid token. Please check your token and try again.');
      }
      if (kDebugMode) print('[AppState] Token valid, saving...');
      await _authService.saveToken(token);
      if (kDebugMode) print('[AppState] Fetching initial data...');
      await fetchInitialData();
      if (kDebugMode) print('[AppState] Initial data fetched successfully');
      
      // Only set authenticated AFTER all data is fetched successfully
      _isAuthenticated = true;
      
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
      if (kDebugMode) print('[AppState] Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

    // Delete token and reset auth state
    await _authService.deleteToken();
    _isAuthenticated = false;

    // Clear all user data
    _projects = [];
    _selectedProject = null;
    _user = null;
    _teams = [];
    _currentTeamId = null;
    _apiService = VercelApi();
    clearFaviconCache();

    // Reset onboarding so user starts fresh
    await resetOnboarding();

    notifyListeners();
  }

  Future<void> fetchInitialData() async {
    _errorMessage = null;
    try {
      // Fetch user info and automatically set team ID
      _user = await _apiService.fetchUserInfoAndSetTeamId();
      if (kDebugMode) print('[AppState] Team ID automatically set: ${_apiService.teamId}');
      
      // Set currentTeamId from the user's defaultTeamId
      if (_user != null && _user!.containsKey('defaultTeamId')) {
        _currentTeamId = _user!['defaultTeamId'] as String?;
        if (kDebugMode) print('[AppState] currentTeamId set to: $_currentTeamId');
      }
      
      await fetchTeams();
      await fetchProjects();
    } on VercelApiException catch (e) {
      // If user not found (404), token is likely invalid/expired
      if (e.statusCode == 404) {
        await logout();
        _errorMessage = 'Session expired. Please log in again.';
        rethrow;
      } else {
        _errorMessage = e.toString();
        rethrow;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) print('Error fetching initial data: $e');
      rethrow;
    }
  }

  Future<void> fetchTeams() async {
    try {
      final response = await _apiService.getTeams();
      _teams = response['teams'] as List<dynamic>? ?? [];
    } catch (e) {
      if (kDebugMode) print('Error fetching teams: $e');
      rethrow;
    }
  }

  Future<void> disconnectFromVercel({SubscriptionProvider? subscriptionProvider}) async {
    // Track disconnect before resetting
    await _superwallService.trackUserAction('disconnect_vercel', context: 'app_state');

    // Reset Superwall (same as logout)
    try {
      await _superwallService.reset();
    } catch (e) {
      if (kDebugMode) print('Superwall disconnect error: $e');
    }

    // Reset subscription state if provider is available
    if (subscriptionProvider != null) {
      try {
        await subscriptionProvider.onUserLogout();
      } catch (e) {
        if (kDebugMode) print('SubscriptionProvider disconnect error: $e');
      }
    }

    // Delete token and reset auth state
    await _authService.deleteToken();
    _isAuthenticated = false;

    // Clear all user data
    _projects = [];
    _selectedProject = null;
    _user = null;
    _teams = [];
    _currentTeamId = null;
    _apiService = VercelApi();
    clearFaviconCache();

    // Reset onboarding so user starts fresh
    await resetOnboarding();

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
