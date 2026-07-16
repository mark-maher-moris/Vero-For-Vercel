import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/demo_api_service.dart';
import '../services/demo_data.dart';
import '../services/superwall_service.dart';
import '../services/widget_service.dart';
import '../models/project.dart';
import 'subscription_provider.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SuperwallService _superwallService = SuperwallService();
  final WidgetService _widgetService = WidgetService();
  VercelApi _apiService = VercelApi();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;
  bool _isDemoMode = false;
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
  bool get isDemoMode => _isDemoMode;
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
    fetchFuture
        .then((_) {
          _faviconInFlightRequests.remove(projectId);
        })
        .catchError((_) {
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
    _hasCompletedOnboarding =
        prefs.getBool('has_completed_onboarding') ?? false;
    _isDemoMode = prefs.getBool('is_demo_mode') ?? false;
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
    await _superwallService.trackUserAction(
      'switch_team',
      context: 'app_state',
      properties: {
        'from_team': previousTeamId ?? 'personal',
        'to_team': teamId ?? 'personal',
      },
    );

    try {
      await fetchProjects();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enter a fully offline demo experience populated with curated data.
  /// No real API calls are made while in demo mode.
  Future<void> enterDemoMode() async {
    if (kDebugMode) print('[AppState] Entering demo mode');
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Swap the API service to the demo implementation so every screen
      // that calls appState.apiService transparently receives demo data.
      _apiService = DemoVercelApi();
      _isDemoMode = true;

      // Populate user/team/projects from the curated demo dataset.
      _user = DemoData.buildUserResponse();
      _currentTeamId = _user?['defaultTeamId'] as String?;
      _teams = (DemoData.buildTeamsResponse()['teams'] as List<dynamic>?) ?? [];
      _projects = DemoData.buildProjects();
      _selectedProject = _projects.isNotEmpty ? _projects.first : null;

      clearFaviconCache();

      // Persist demo mode state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_demo_mode', true);

      // Mark onboarding as complete so returning to login after demo exit
      // keeps navigation clean.
      await prefs.setBool('has_completed_onboarding', true);
      _hasCompletedOnboarding = true;

      _isAuthenticated = true;

      await _widgetService.pushDemoData();

      await _superwallService.trackUserAction(
        'enter_demo_mode',
        context: 'app_state',
      );
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) print('[AppState] enterDemoMode error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Exit demo mode and return the user to the login screen so they can
  /// connect a real Vercel account. Does NOT touch any stored token because
  /// demo mode never saves one.
  Future<void> exitDemoMode({
    SubscriptionProvider? subscriptionProvider,
  }) async {
    if (kDebugMode) print('[AppState] Exiting demo mode');
    await _superwallService.trackUserAction(
      'exit_demo_mode',
      context: 'app_state',
    );

    // Do NOT reset Superwall or SubscriptionProvider here.
    // Exiting demo mode shouldn't lose the anonymous purchase state.
    // The purchase will be aliased to the user ID when they log in.

    _isDemoMode = false;
    _isAuthenticated = false;
    _projects = [];
    _selectedProject = null;
    _user = null;
    _teams = [];
    _currentTeamId = null;
    _apiService = VercelApi();
    clearFaviconCache();

    // Persist demo mode state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_demo_mode', false);

    // Keep onboarding flag so Consumer goes straight to LoginScreen.
    _hasCompletedOnboarding = true;

    notifyListeners();
  }

  Future<void> login(
    String token, {
    SubscriptionProvider? subscriptionProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (kDebugMode) print('[AppState] Login started');
    try {
      // Validate token before saving
      if (kDebugMode) print('[AppState] Validating token...');
      final isValid = await _authService.validateToken(token);
      if (!isValid) {
        throw Exception(
          'Invalid token. Please check your token and try again.',
        );
      }
      if (kDebugMode) print('[AppState] Token valid, saving...');
      await _authService.saveToken(token);

      // Ensure demo mode is disabled and the API service is reset to the real client
      _isDemoMode = false;
      _apiService = VercelApi();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_demo_mode', false);

      if (kDebugMode) print('[AppState] Fetching initial data...');
      await fetchInitialData();
      if (kDebugMode) print('[AppState] Initial data fetched successfully');

      // Only set authenticated AFTER all data is fetched successfully
      _isAuthenticated = true;

      // Sync login with Superwall using user ID
      if (_user != null && _user!['id'] != null) {
        final userId = _user!['id'].toString();

        if (subscriptionProvider != null) {
          await subscriptionProvider.onUserLogin(userId);
        } else {
          await _superwallService.identify(userId);
        }

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
        await _superwallService.trackUserAction(
          'login_success',
          context: 'app_state',
        );
      }

      await _pushWidgetData();
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
    _isDemoMode = false;

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
      if (kDebugMode) {
        print('[AppState] Team ID automatically set: ${_apiService.teamId}');
      }

      // Set currentTeamId from the user's defaultTeamId
      if (_user != null && _user!.containsKey('defaultTeamId')) {
        _currentTeamId = _user!['defaultTeamId'] as String?;
        if (kDebugMode) {
          print('[AppState] currentTeamId set to: $_currentTeamId');
        }
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

  Future<void> disconnectFromVercel({
    SubscriptionProvider? subscriptionProvider,
  }) async {
    // Track disconnect before resetting
    await _superwallService.trackUserAction(
      'disconnect_vercel',
      context: 'app_state',
    );

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
    _isDemoMode = false;

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
      await _pushWidgetData();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<void> _pushWidgetData() async {
    try {
      await _widgetService.initialize();
      final isSubscribed = await _superwallService
          .getCurrentSubscriptionStatus();
      await _widgetService.pushAuthData(
        userId: _user?['id']?.toString(),
        teamId: _currentTeamId,
        isSubscribed: isSubscribed,
        isDemoMode: _isDemoMode,
      );
      final projectList = _projects
          .map((p) => <String, String>{'id': p.id, 'name': p.name})
          .toList();
      await _widgetService.pushProjects(projectList);
      if (_isDemoMode) {
        await _widgetService.triggerAllWidgetUpdates();
      } else if (_isAuthenticated) {
        await _widgetService.refreshAll(
          api: _apiService,
          projects: projectList,
        );
      }
    } catch (e) {
      if (kDebugMode) print('[AppState] _pushWidgetData error: $e');
    }
  }

  Future<void> refreshWidgets() => _pushWidgetData();

  Future<void> setWidgetProject(
    String widgetType,
    String projectId,
    String projectName,
  ) async {
    await _widgetService.initialize();
    await _widgetService.setProjectForWidget(
      widgetType,
      projectId,
      projectName,
    );
    await _pushWidgetData();
  }
}
