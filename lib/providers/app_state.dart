import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/project.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final VercelApi _apiService = VercelApi();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  List<Project> _projects = [];
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  List<Project> get projects => _projects;
  Map<String, dynamic>? get user => _user;

  AppState() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    _isLoading = true;
    notifyListeners();
    _isAuthenticated = await _authService.isAuthenticated();
    if (_isAuthenticated) {
      await fetchInitialData();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String token) async {
    _isLoading = true;
    notifyListeners();
    await _authService.saveToken(token);
    _isAuthenticated = true;
    await fetchInitialData();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loginWithOAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.loginWithVercel();
      _isAuthenticated = true;
      await fetchInitialData();
    } catch (e) {
      if (kDebugMode) print('OAuth login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.deleteToken();
    _isAuthenticated = false;
    _projects = [];
    _user = null;
    notifyListeners();
  }

  Future<void> fetchInitialData() async {
    try {
      _user = await _apiService.getUser();
      _projects = await _apiService.getProjects();
    } catch (e) {
      if (kDebugMode) print('Error fetching data: \$e');
      // If unauthorized, we could logout here
    }
    notifyListeners();
  }
}
