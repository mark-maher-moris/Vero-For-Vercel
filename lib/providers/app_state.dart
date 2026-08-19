import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/demo_api_service.dart';
import '../services/demo_data.dart';
import '../services/superwall_service.dart';
import '../services/account_entitlement_policy.dart';
import '../services/widget_service.dart';
import '../services/whats_new_service.dart';
import '../models/project.dart';
import '../models/vercel_account.dart';
import 'subscription_provider.dart';

class TokenScopeException implements Exception {
  final String message;

  const TokenScopeException(this.message);

  @override
  String toString() => message;
}

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SuperwallService _superwallService = SuperwallService();
  final WidgetService _widgetService = WidgetService();
  final WhatsNewService _whatsNewService = WhatsNewService();
  VercelApi _apiService = VercelApi();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;
  bool _isDemoMode = false;
  String? _errorMessage;
  String? _accessWarning;

  List<VercelAccount> _accounts = [];
  VercelAccount? _activeAccount;

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

  List<VercelAccount> get accounts => _accounts;
  VercelAccount? get activeAccount => _activeAccount;
  int get accountCount => _accounts.length;

  /// A non-blocking notice shown when a valid token deliberately has limited
  /// Vercel permissions.
  String? get accessWarning => _accessWarning;
  List<Project> get projects => _projects;
  Project? get selectedProject => _selectedProject;
  Map<String, dynamic>? get user => _user;
  List<dynamic> get teams => _teams;
  String? get currentTeamId => _currentTeamId;
  VercelApi get apiService => _apiService;
  Map<String, String?> get faviconCache => _faviconCache;
  bool _accountConnectionInProgress = false;

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
    _initializeState();
  }

  /// Identify the app-level purchaser in Superwall.
  ///
  /// This must not use a Vercel account ID because the user can connect and
  /// switch between multiple Vercel accounts while retaining one purchase.
  Future<void> syncBillingIdentity() async {
    try {
      final billingUserId = await _authService.getOrCreateBillingUserId();
      await _superwallService.identify(billingUserId);
    } catch (e) {
      if (kDebugMode) {
        print('[AppState] Billing identity sync error: $e');
      }
    }
  }

  Future<void> _initializeState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedOnboarding =
          prefs.getBool('has_completed_onboarding') ?? false;
      final savedDemoMode = prefs.getBool('is_demo_mode') ?? false;

      _accounts = await _authService.getAccounts();
      _activeAccount = await _authService.getActiveAccount();
      _isAuthenticated =
          _activeAccount != null && _activeAccount!.token.isNotEmpty;

      await syncBillingIdentity();

      if (_isAuthenticated && _activeAccount != null) {
        _isDemoMode = false;
        final teamScope = _activeAccount!.teamScope;
        _currentTeamId = teamScope;
        _apiService = VercelApi(teamId: teamScope);
        await fetchInitialData();
      } else if (savedDemoMode) {
        // Restore demo mode state seamlessly
        _isDemoMode = true;
        _apiService = DemoVercelApi();
        _user = DemoData.buildUserResponse();
        _currentTeamId = _user?['defaultTeamId'] as String?;
        _teams =
            (DemoData.buildTeamsResponse()['teams'] as List<dynamic>?) ?? [];
        _projects = DemoData.buildProjects();
        _selectedProject = _projects.isNotEmpty ? _projects.first : null;
        _isAuthenticated = true;
        clearFaviconCache();
        await _pushWidgetData();
      } else {
        _isDemoMode = false;
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (e is TokenScopeException ||
          (e is VercelApiException && e.statusCode == 401)) {
        if (_activeAccount != null) {
          await _authService.removeAccount(_activeAccount!.id);
          _accounts = await _authService.getAccounts();
          _activeAccount = await _authService.getActiveAccount();
          _isAuthenticated = _activeAccount != null;
        } else {
          await _authService.deleteToken();
          _isAuthenticated = false;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      await _checkAndDeliverWhatsNew();
    }
  }

  Future<void> _checkAndDeliverWhatsNew({bool? isProUser}) async {
    try {
      final isPro =
          isProUser ?? await _superwallService.getCurrentSubscriptionStatus();
      await _whatsNewService.checkAndDeliverWhatsNew(isProUser: isPro);
    } catch (e) {
      if (kDebugMode) {
        print('[AppState] What\'s New notification error: $e');
      }
    }
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
    await prefs.setBool('is_demo_mode', false);
    _hasCompletedOnboarding = false;
    _isDemoMode = false;
    notifyListeners();
  }

  /// Switch active account
  Future<void> switchAccount(String accountId) async {
    if (_activeAccount?.id == accountId) return;

    final targetAccount = _accounts.where((a) => a.id == accountId).toList();
    if (targetAccount.isEmpty) return;

    final previousAccountId = _activeAccount?.id;
    final selectedAccount = targetAccount.first;

    _isLoading = true;
    _errorMessage = null;
    _accessWarning = null;
    clearFaviconCache();

    _activeAccount = selectedAccount;
    await _authService.setActiveAccountId(accountId);
    _currentTeamId = selectedAccount.teamScope;
    _apiService = VercelApi(teamId: selectedAccount.teamScope);
    notifyListeners();

    // Track account switch event
    await _superwallService.trackUserAction(
      'switch_account',
      context: 'app_state',
      properties: {
        'from_account_id': previousAccountId ?? 'none',
        'to_account_id': accountId,
        'username': selectedAccount.username,
      },
    );

    try {
      await fetchInitialData();

      // Keep the purchaser identity stable while updating account-scoped
      // attributes for segmentation and support.
      if (_user != null && _user!['id'] != null) {
        final userId = _user!['id'].toString();
        final billingUserId = await _authService.getOrCreateBillingUserId();
        await _superwallService.identify(billingUserId);
        await _superwallService.setUserAttributes({
          'billing_user_id': billingUserId,
          'vercel_user_id': userId,
          'vercel_account_id': accountId,
          'username': _user!['username'] ?? selectedAccount.username,
          'email': _user!['email'] ?? selectedAccount.email ?? '',
          'plan': _user!['plan'] ?? 'free',
          'account_count': _accounts.length,
          'project_count': _projects.length,
          'team_count': _teams.length,
        });
      }

      await _checkAndDeliverWhatsNew();

      await _pushWidgetData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Connect a new Vercel account (or replace an existing account token)
  Future<void> connectNewAccount(
    String token, {
    String? teamId,
    String? replaceAccountId,
    SubscriptionProvider? subscriptionProvider,
    bool isAdditionalAccount = false,
  }) async {
    if (_accountConnectionInProgress) {
      throw Exception('Another account connection is already in progress.');
    }
    _accountConnectionInProgress = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedToken = token.trim();
    final normalizedTeamId = teamId?.trim();
    final isTeamScoped =
        normalizedTeamId != null && normalizedTeamId.isNotEmpty;

    try {
      final addingAccount =
          isAdditionalAccount ||
          (replaceAccountId == null && _accounts.isNotEmpty);
      if (replaceAccountId != null &&
          !_accounts.any((account) => account.id == replaceAccountId)) {
        throw Exception('The account being replaced no longer exists.');
      }

      if (addingAccount && replaceAccountId == null) {
        if (!AccountEntitlementPolicy.canStartAdditionalAccount(
          accountCount: _accounts.length,
        )) {
          throw Exception(
            _accounts.length >= AccountEntitlementPolicy.maxConnectedAccounts
                ? 'You can connect a maximum of ${AccountEntitlementPolicy.maxConnectedAccounts} Vercel accounts.'
                : 'Connect your first Vercel account before adding another one.',
          );
        }

        final authorized =
            await subscriptionProvider?.authorizeAdditionalAccount(
              currentAccountCount: _accounts.length,
            ) ??
            false;
        if (!authorized) {
          throw Exception(
            'The additional-account purchase is required before connecting another Vercel account.',
          );
        }
      }

      // 1. Check for duplicate token
      if (replaceAccountId != null) {
        if (_accounts.any(
          (a) => a.id == replaceAccountId && a.token.trim() == normalizedToken,
        )) {
          throw Exception(
            'This is the same token already in use by this account.',
          );
        }
        if (_accounts.any(
          (a) => a.id != replaceAccountId && a.token.trim() == normalizedToken,
        )) {
          throw Exception(
            'This Vercel token is already connected as another account.',
          );
        }
      } else {
        if (_accounts.any((a) => a.token.trim() == normalizedToken)) {
          throw Exception(
            'This Vercel token is already connected as an account.',
          );
        }
      }

      // 2. Validate token against Vercel API
      final status = await _authService.validateTokenDetails(
        normalizedToken,
        teamId: isTeamScoped ? normalizedTeamId : null,
      );

      if (status == TokenValidationStatus.teamScoped) {
        throw TeamScopeRequiredException(
          'This token is restricted to a team. Please enter your Team ID or slug.',
        );
      }

      if (status != TokenValidationStatus.valid) {
        throw Exception(
          isTeamScoped
              ? 'This token cannot access that team. Check the token and team ID or slug.'
              : 'Invalid token. Please check your token and try again.',
        );
      }

      // 3. Fetch account details to populate metadata
      final details = await _authService.fetchAccountDetails(
        normalizedToken,
        teamId: isTeamScoped ? normalizedTeamId : null,
      );
      final user = details?['user'] as Map<String, dynamic>?;

      // 4. Check for duplicate user ID if not replacing and not team scoped
      if (user != null && user['id'] != null) {
        final userId = user['id'].toString();
        final username = user['username']?.toString() ?? 'user';
        if (_accounts.any(
          (a) =>
              a.id != replaceAccountId &&
              a.id == userId &&
              a.teamScope == (isTeamScoped ? normalizedTeamId : null),
        )) {
          throw Exception('Account "@$username" is already connected.');
        }
      }

      // 5. If replacing an existing account and ID will change, remove old entry from storage
      final accountId =
          user?['id']?.toString() ??
          (isTeamScoped
              ? 'team_$normalizedTeamId'
              : (replaceAccountId ??
                    'account_${DateTime.now().millisecondsSinceEpoch}'));

      if (replaceAccountId != null && replaceAccountId != accountId) {
        await _authService.removeAccount(replaceAccountId);
      }

      // 6. Construct new VercelAccount model
      final newAccount = VercelAccount(
        id: accountId,
        token: normalizedToken,
        teamScope: isTeamScoped ? normalizedTeamId : null,
        name:
            user?['name'] as String? ??
            user?['username'] as String? ??
            'Vercel Account',
        username:
            user?['username'] as String? ??
            (isTeamScoped ? normalizedTeamId : 'user'),
        email: user?['email'] as String?,
        avatar: user?['avatar'] as String?,
        defaultTeamId: user?['defaultTeamId'] as String?,
        createdAt: DateTime.now(),
        isTeamScopedOnly: isTeamScoped && user == null,
      );

      // 7. Save new account & set as active
      await _authService.addOrUpdateAccount(newAccount, makeActive: true);
      _accounts = await _authService.getAccounts();
      _activeAccount = newAccount;

      // 8. Reset demo mode & initialize API client
      _isDemoMode = false;
      _currentTeamId = isTeamScoped ? normalizedTeamId : null;
      _apiService = VercelApi(teamId: isTeamScoped ? normalizedTeamId : null);
      clearFaviconCache();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_demo_mode', false);
      await prefs.setBool('has_completed_onboarding', true);
      _hasCompletedOnboarding = true;

      // 9. Fetch fresh data for the newly connected account
      _accessWarning = null;
      await fetchInitialData();
      _isAuthenticated = true;

      // 10. Sync with Superwall using the stable billing identity and update
      // account-scoped segmentation attributes.
      final billingUserId = await _authService.getOrCreateBillingUserId();
      if (subscriptionProvider != null) {
        await subscriptionProvider.onUserLogin(billingUserId);
      } else {
        await _superwallService.identify(billingUserId);
      }

      final hasProEntitlement =
          subscriptionProvider?.hasProEntitlement ??
          await _superwallService.hasEntitlement(
            AccountEntitlementPolicy.proEntitlementId,
          );

      await _superwallService.setUserAttributes({
        'billing_user_id': billingUserId,
        'vercel_user_id': user?['id']?.toString() ?? accountId,
        'vercel_account_id': accountId,
        'username': _user?['username'] ?? newAccount.username,
        'email': _user?['email'] ?? newAccount.email ?? '',
        'plan': _user?['plan'] ?? 'free',
        'account_count': _accounts.length,
        'project_count': _projects.length,
        'team_count': _teams.length,
        'has_pro': hasProEntitlement,
      });

      await _checkAndDeliverWhatsNew(isProUser: subscriptionProvider?.isPro);

      await _superwallService.trackUserAction(
        replaceAccountId != null
            ? 'replace_account_token_success'
            : 'connect_new_account_success',
        context: 'app_state',
        properties: {'account_count': _accounts.length},
      );

      await _pushWidgetData();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) print('[AppState] connectNewAccount error: $e');
      rethrow;
    } finally {
      _accountConnectionInProgress = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Disconnect a specific account
  Future<void> disconnectAccount(
    String accountId, {
    SubscriptionProvider? subscriptionProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _superwallService.trackUserAction(
        'disconnect_account',
        context: 'app_state',
        properties: {'account_id': accountId},
      );

      // If this is the only account, do a full disconnect
      if (_accounts.length <= 1) {
        await disconnectFromVercel(subscriptionProvider: subscriptionProvider);
        return;
      }

      // Remove the specific account
      await _authService.removeAccount(accountId);
      _accounts = await _authService.getAccounts();
      _activeAccount = await _authService.getActiveAccount();

      if (_activeAccount != null) {
        _currentTeamId = _activeAccount!.teamScope;
        _apiService = VercelApi(teamId: _activeAccount!.teamScope);
        clearFaviconCache();
        await fetchInitialData();
        await _pushWidgetData();
      } else {
        await disconnectFromVercel(subscriptionProvider: subscriptionProvider);
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
      _apiService = DemoVercelApi();
      _isDemoMode = true;

      _user = DemoData.buildUserResponse();
      _currentTeamId = _user?['defaultTeamId'] as String?;
      _teams = (DemoData.buildTeamsResponse()['teams'] as List<dynamic>?) ?? [];
      _projects = DemoData.buildProjects();
      _selectedProject = _projects.isNotEmpty ? _projects.first : null;

      clearFaviconCache();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_demo_mode', true);
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
  /// connect a real Vercel account. Does NOT touch any stored accounts.
  Future<void> exitDemoMode({
    SubscriptionProvider? subscriptionProvider,
  }) async {
    if (kDebugMode) print('[AppState] Exiting demo mode');
    await _superwallService.trackUserAction(
      'exit_demo_mode',
      context: 'app_state',
    );

    _isDemoMode = false;
    _projects = [];
    _selectedProject = null;
    _user = null;
    _teams = [];
    _currentTeamId = null;
    clearFaviconCache();

    // Check if there are real accounts connected
    _accounts = await _authService.getAccounts();
    _activeAccount = await _authService.getActiveAccount();
    _isAuthenticated =
        _activeAccount != null && _activeAccount!.token.isNotEmpty;

    if (_isAuthenticated && _activeAccount != null) {
      _currentTeamId = _activeAccount!.teamScope;
      _apiService = VercelApi(teamId: _activeAccount!.teamScope);
      await fetchInitialData();
    } else {
      _apiService = VercelApi();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_demo_mode', false);
    _hasCompletedOnboarding = true;

    notifyListeners();
  }

  /// Connect / login with a token (used by login screen and onboarding)
  Future<void> login(
    String token, {
    SubscriptionProvider? subscriptionProvider,
    String? teamId,
    bool isAdditionalAccount = false,
  }) async {
    await connectNewAccount(
      token,
      teamId: teamId,
      subscriptionProvider: subscriptionProvider,
      isAdditionalAccount: isAdditionalAccount,
    );
  }

  /// Update an existing account's token in-place (e.g. after session expiry or token rotation)
  Future<void> updateAccountToken(
    String accountId,
    String newToken, {
    String? teamId,
    SubscriptionProvider? subscriptionProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _accessWarning = null;
    notifyListeners();

    final normalizedToken = newToken.trim();
    final normalizedTeamId = teamId?.trim();
    final isTeamScoped =
        normalizedTeamId != null && normalizedTeamId.isNotEmpty;

    try {
      // 1. Check for duplicate token in OTHER accounts
      if (_accounts.any(
        (a) => a.id != accountId && a.token.trim() == normalizedToken,
      )) {
        throw Exception(
          'This Vercel token is already used by another connected account.',
        );
      }

      // 2. Validate token against Vercel API
      final status = await _authService.validateTokenDetails(
        normalizedToken,
        teamId: isTeamScoped ? normalizedTeamId : null,
      );

      if (status == TokenValidationStatus.teamScoped) {
        throw TeamScopeRequiredException(
          'This token is restricted to a team. Please enter your Team ID or slug.',
        );
      }

      if (status != TokenValidationStatus.valid) {
        throw Exception(
          isTeamScoped
              ? 'This token cannot access that team. Check the token and team ID or slug.'
              : 'Invalid token. Please check your token and try again.',
        );
      }

      // 3. Update account in storage
      final updatedAccount = await _authService.updateAccountToken(
        accountId,
        normalizedToken,
        teamId: isTeamScoped ? normalizedTeamId : null,
      );

      if (updatedAccount == null) {
        throw Exception('Account not found.');
      }

      _accounts = await _authService.getAccounts();
      _activeAccount = await _authService.getActiveAccount();

      // 4. Re-initialize API client and fetch fresh data if this is the active account
      if (_activeAccount?.id == accountId) {
        _isDemoMode = false;
        _currentTeamId = isTeamScoped
            ? normalizedTeamId
            : _activeAccount!.teamScope;
        _apiService = VercelApi(teamId: _currentTeamId);
        clearFaviconCache();

        await fetchInitialData();
        _isAuthenticated = true;

        if (subscriptionProvider != null) {
          await subscriptionProvider.onUserLogin(
            await _authService.getOrCreateBillingUserId(),
          );
        } else {
          await syncBillingIdentity();
        }

        await _pushWidgetData();
      }

      await _superwallService.trackUserAction(
        'update_account_token_success',
        context: 'app_state',
        properties: {'account_id': accountId},
      );
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) print('[AppState] updateAccountToken error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout({SubscriptionProvider? subscriptionProvider}) async {
    await _superwallService.trackUserAction('logout', context: 'app_state');

    if (subscriptionProvider != null) {
      try {
        await subscriptionProvider.onUserLogout();
      } catch (e) {
        if (kDebugMode) print('SubscriptionProvider logout error: $e');
      }
    }

    await _widgetService.clearAuthData();
    await _authService.deleteToken();
    _isAuthenticated = false;
    _isDemoMode = false;
    _accounts = [];
    _activeAccount = null;

    _projects = [];
    _selectedProject = null;
    _user = null;
    _teams = [];
    _currentTeamId = null;
    _apiService = VercelApi();
    clearFaviconCache();

    await resetOnboarding();

    notifyListeners();
  }

  Future<void> disconnectFromVercel({
    SubscriptionProvider? subscriptionProvider,
  }) async {
    await _superwallService.trackUserAction(
      'disconnect_vercel',
      context: 'app_state',
    );

    if (subscriptionProvider != null) {
      try {
        await subscriptionProvider.onUserLogout();
      } catch (e) {
        if (kDebugMode) print('SubscriptionProvider disconnect error: $e');
      }
    }

    await _widgetService.clearAuthData();
    await _authService.deleteToken();
    _isAuthenticated = false;
    _isDemoMode = false;
    _accounts = [];
    _activeAccount = null;

    _projects = [];
    _selectedProject = null;
    _user = null;
    _teams = [];
    _currentTeamId = null;
    _apiService = VercelApi();
    clearFaviconCache();

    await resetOnboarding();

    notifyListeners();
  }

  Future<void> fetchInitialData() async {
    _errorMessage = null;
    _accessWarning = null;
    var couldLoadUser = false;
    try {
      _user = await _apiService.fetchUserInfoAndSetTeamId();
      couldLoadUser = _user != null && _user!.isNotEmpty;

      // Update active account metadata in memory and storage if user info arrived
      if (_activeAccount != null && _user != null && _user!.isNotEmpty) {
        final userData = _user!['user'] as Map<String, dynamic>? ?? _user!;
        final updated = _activeAccount!.copyWith(
          name: userData['name'] as String? ?? _activeAccount!.name,
          username: userData['username'] as String? ?? _activeAccount!.username,
          email: userData['email'] as String? ?? _activeAccount!.email,
          avatar: userData['avatar'] as String? ?? _activeAccount!.avatar,
          defaultTeamId:
              userData['defaultTeamId'] as String? ??
              _activeAccount!.defaultTeamId,
        );
        _activeAccount = updated;
        await _authService.addOrUpdateAccount(updated, makeActive: true);
        _accounts = await _authService.getAccounts();
      }

      if (_currentTeamId == null &&
          _user != null &&
          _user!.containsKey('defaultTeamId') &&
          _user!['defaultTeamId'] != null) {
        _currentTeamId = _user!['defaultTeamId'] as String?;
      }
    } on VercelApiException catch (e) {
      if (e.statusCode == 401) {
        _errorMessage = 'Session expired. Please re-authenticate your token.';
        rethrow;
      }
      if (e.statusCode != 403 && e.statusCode != 404) rethrow;
      _user = null;
      _accessWarning =
          'Limited access: account details and some Vercel features are unavailable for this token.';
    }

    try {
      await fetchTeams();
    } on VercelApiException catch (e) {
      if (e.statusCode == 401) rethrow;
      if (e.statusCode != 403 && e.statusCode != 404) rethrow;
      _teams = [];
      _accessWarning ??=
          'Limited access: team list is unavailable for this scoped token.';
    }

    try {
      await fetchProjects();
    } on VercelApiException catch (e) {
      if (e.statusCode == 401) rethrow;
      if (e.statusCode == 403 || e.statusCode == 404) {
        final exception = TokenScopeException(
          'This token is valid but cannot read projects for the selected account or team. Grant project access, or enter the correct Team ID or slug.',
        );
        _errorMessage = exception.message;
        throw exception;
      }
      rethrow;
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

  Future<void> pauseProject(String projectId) async {
    await _apiService.pauseProject(projectId);
    await fetchProjects();
  }

  Future<void> unpauseProject(String projectId) async {
    await _apiService.unpauseProject(projectId);
    await fetchProjects();
  }

  Future<void> _pushWidgetData() async {
    try {
      await _widgetService.initialize();
      final isSubscribed = await _superwallService
          .getCurrentSubscriptionStatus();
      await _widgetService.pushAuthData(
        userId: _activeAccount?.id ?? _user?['id']?.toString(),
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
