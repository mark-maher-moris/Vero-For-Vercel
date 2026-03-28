import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/revenue_cat_service.dart';
import '../models/project.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final RevenueCatService _revenueCatService = RevenueCatService();
  VercelApi _apiService = VercelApi();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  List<Project> _projects = [];
  Project? _selectedProject;
  Map<String, dynamic>? _user;
  List<dynamic> _teams = [];
  String? _currentTeamId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
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
    _currentTeamId = teamId;
    _apiService = VercelApi(teamId: teamId);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
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
      // Validate token before saving
      final isValid = await _authService.validateToken(token);
      if (!isValid) {
        throw Exception('Invalid token. Please check your token and try again.');
      }
      await _authService.saveToken(token);
      _isAuthenticated = true;
      await fetchInitialData();
      
      // Sync login with RevenueCat using user ID
      if (_user != null && _user!['id'] != null) {
        await _revenueCatService.login(_user!['id'].toString());
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Sync logout with RevenueCat
    try {
      await _revenueCatService.logout();
    } catch (e) {
      if (kDebugMode) print('RevenueCat logout error: $e');
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

  Future<void> fetchInitialData() async {
    _errorMessage = null;
    try {
      // Fetch user and teams first
      _user = await _apiService.getUser();
      await fetchTeams();
      await fetchProjects();
    } on VercelApiException catch (e) {
      // If user not found (404), token is likely invalid/expired
      if (e.statusCode == 404) {
        await logout();
        _errorMessage = 'Session expired. Please log in again.';
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

  Future<void> fetchProjects() async {
    try {
      _projects = await _apiService.getProjects();
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
