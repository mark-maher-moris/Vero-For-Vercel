import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/vercel_account.dart';

enum TokenValidationStatus { valid, invalid, teamScoped, networkError }

class TeamScopeRequiredException implements Exception {
  final String message;
  TeamScopeRequiredException([
    this.message =
        'This token is restricted to a team. Please enter your Team ID or slug.',
  ]);

  @override
  String toString() => message;
}

class AuthService {
  static const String _tokenKey = 'vercel_access_token';
  static const String _teamScopeKey = 'vercel_team_scope';
  static const String _migrationKey = 'migrated_to_secure_storage';
  static const String _accountsKey = 'vercel_accounts_json';
  static const String _activeAccountIdKey = 'vercel_active_account_id';
  static const String _multiAccountMigrationKey =
      'migrated_to_multi_account_v1';
  static const String _billingUserIdKey = 'vero_billing_user_id';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Returns the stable app-level identity used for purchase ownership.
  ///
  /// Vercel account IDs are not billing identities: one Vero user can connect
  /// more than one Vercel account. This ID is intentionally kept when Vercel
  /// accounts are disconnected so a purchase remains available on the device.
  Future<String> getOrCreateBillingUserId() async {
    final existing = await _secureStorage.read(key: _billingUserIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String byteHex(int value) => value.toRadixString(16).padLeft(2, '0');
    final id = [
      bytes.sublist(0, 4),
      bytes.sublist(4, 6),
      bytes.sublist(6, 8),
      bytes.sublist(8, 10),
      bytes.sublist(10, 16),
    ].map((group) => group.map(byteHex).join()).join('-');

    await _secureStorage.write(key: _billingUserIdKey, value: id);
    return id;
  }

  /// Fetch all stored connected accounts, running migration from single-account if necessary
  Future<List<VercelAccount>> getAccounts() async {
    await _migrateFromSharedPreferences();
    await _migrateToMultiAccount();

    try {
      final jsonStr = await _secureStorage.read(key: _accountsKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((item) => VercelAccount.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('[AuthService] Error reading accounts: $e');
      return [];
    }
  }

  /// Get the currently active account
  Future<VercelAccount?> getActiveAccount() async {
    final accounts = await getAccounts();
    if (accounts.isEmpty) return null;

    final activeId = await _secureStorage.read(key: _activeAccountIdKey);
    if (activeId != null) {
      final match = accounts.where((a) => a.id == activeId).toList();
      if (match.isNotEmpty) return match.first;
    }

    // Default to the first account if none is active or ID not found
    final first = accounts.first;
    await setActiveAccountId(first.id);
    return first;
  }

  /// Set the active account ID and synchronize legacy keys for compatibility
  Future<void> setActiveAccountId(String accountId) async {
    await _secureStorage.write(key: _activeAccountIdKey, value: accountId);

    // Sync legacy token & team scope for active account so native widgets & any legacy readers work
    final accounts = await getAccounts();
    final match = accounts.where((a) => a.id == accountId).toList();
    if (match.isNotEmpty) {
      final active = match.first;
      await _secureStorage.write(key: _tokenKey, value: active.token);
      if (active.teamScope != null && active.teamScope!.isNotEmpty) {
        await _secureStorage.write(
          key: _teamScopeKey,
          value: active.teamScope!,
        );
      } else {
        await _secureStorage.delete(key: _teamScopeKey);
      }
    }
  }

  /// Save the full list of accounts to secure storage
  Future<void> saveAccounts(List<VercelAccount> accounts) async {
    final jsonStr = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _secureStorage.write(key: _accountsKey, value: jsonStr);

    final activeId = await _secureStorage.read(key: _activeAccountIdKey);
    if (activeId == null || !accounts.any((a) => a.id == activeId)) {
      if (accounts.isNotEmpty) {
        await setActiveAccountId(accounts.first.id);
      } else {
        await _secureStorage.delete(key: _activeAccountIdKey);
        await _secureStorage.delete(key: _tokenKey);
        await _secureStorage.delete(key: _teamScopeKey);
      }
    }
  }

  /// Add or update an account and optionally set it as active
  Future<void> addOrUpdateAccount(
    VercelAccount account, {
    bool makeActive = true,
  }) async {
    final accounts = await getAccounts();

    // Remove any existing account with matching ID or token
    accounts.removeWhere(
      (a) => a.id == account.id || a.token.trim() == account.token.trim(),
    );

    accounts.add(account);
    await saveAccounts(accounts);

    if (makeActive) {
      await setActiveAccountId(account.id);
    }
  }

  /// Update an existing account's token in-place and refresh its metadata
  Future<VercelAccount?> updateAccountToken(
    String accountId,
    String newToken, {
    String? teamId,
  }) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return null;

    final existing = accounts[index];
    final normalizedToken = newToken.trim();
    final normalizedTeamId = teamId?.trim() ?? existing.teamScope;

    // Fetch refreshed user info if possible
    Map<String, dynamic>? details;
    try {
      details = await fetchAccountDetails(
        normalizedToken,
        teamId: normalizedTeamId,
      );
    } catch (_) {}

    final user = details?['user'] as Map<String, dynamic>?;

    final updated = existing.copyWith(
      token: normalizedToken,
      teamScope: normalizedTeamId,
      name: user?['name'] as String? ?? existing.name,
      username: user?['username'] as String? ?? existing.username,
      email: user?['email'] as String? ?? existing.email,
      avatar: user?['avatar'] as String? ?? existing.avatar,
      defaultTeamId:
          user?['defaultTeamId'] as String? ?? existing.defaultTeamId,
    );

    accounts[index] = updated;
    await saveAccounts(accounts);

    final activeId = await _secureStorage.read(key: _activeAccountIdKey);
    if (activeId == accountId) {
      await setActiveAccountId(accountId);
    }

    return updated;
  }

  /// Remove a connected account. If it was active, switch to another account.
  Future<void> removeAccount(String accountId) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == accountId);

    if (accounts.isEmpty) {
      await deleteToken();
    } else {
      await saveAccounts(accounts);
      final activeId = await _secureStorage.read(key: _activeAccountIdKey);
      if (activeId == accountId) {
        await setActiveAccountId(accounts.first.id);
      }
    }
  }

  /// Fetch active token (backward-compatible)
  Future<String?> getToken() async {
    final active = await getActiveAccount();
    if (active != null) return active.token;

    // Fallback check legacy key
    String? token = await _secureStorage.read(key: _tokenKey);
    if (token != null) return token;

    await _migrateFromSharedPreferences();
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Update active account's token or save initial token
  Future<void> saveToken(String token) async {
    final active = await getActiveAccount();
    if (active != null) {
      final updated = active.copyWith(token: token);
      await addOrUpdateAccount(updated, makeActive: true);
    } else {
      // Create initial account
      final details = await fetchAccountDetails(token);
      final user = details?['user'] as Map<String, dynamic>?;
      final account = VercelAccount(
        id:
            user?['id']?.toString() ??
            'account_${DateTime.now().millisecondsSinceEpoch}',
        token: token,
        name:
            user?['name'] as String? ??
            user?['username'] as String? ??
            'Vercel Account',
        username: user?['username'] as String? ?? 'user',
        email: user?['email'] as String?,
        avatar: user?['avatar'] as String?,
        defaultTeamId: user?['defaultTeamId'] as String?,
        createdAt: DateTime.now(),
      );
      await addOrUpdateAccount(account, makeActive: true);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
    await prefs.setBool(_multiAccountMigrationKey, true);
  }

  /// Fetch active team scope (backward-compatible)
  Future<String?> getTeamScope() async {
    final active = await getActiveAccount();
    if (active != null) return active.teamScope;
    return await _secureStorage.read(key: _teamScopeKey);
  }

  /// Save team scope for the active account
  Future<void> saveTeamScope(String? teamId) async {
    final active = await getActiveAccount();
    if (active != null) {
      final updated = active.copyWith(
        teamScope: (teamId != null && teamId.trim().isNotEmpty)
            ? teamId.trim()
            : null,
      );
      await addOrUpdateAccount(updated, makeActive: true);
    } else {
      if (teamId == null || teamId.trim().isEmpty) {
        await _secureStorage.delete(key: _teamScopeKey);
      } else {
        await _secureStorage.write(key: _teamScopeKey, value: teamId.trim());
      }
    }
  }

  /// Delete all stored accounts and tokens (full logout)
  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _accountsKey);
      await _secureStorage.delete(key: _activeAccountIdKey);
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _teamScopeKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_teamScopeKey);
      await prefs.setBool(_migrationKey, true);
      await prefs.setBool(_multiAccountMigrationKey, true);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isAuthenticated() async {
    final active = await getActiveAccount();
    return active != null && active.token.isNotEmpty;
  }

  /// Validates a token and returns a detailed validation status (e.g. valid, invalid, teamScoped)
  Future<TokenValidationStatus> validateTokenDetails(
    String token, {
    String? teamId,
  }) async {
    final normalizedTeamId = teamId?.trim();
    final isTeamScoped =
        normalizedTeamId != null && normalizedTeamId.isNotEmpty;
    final uri = isTeamScoped
        ? Uri.parse(
            'https://api.vercel.com/v10/projects',
          ).replace(queryParameters: {'teamId': normalizedTeamId, 'limit': '1'})
        : Uri.parse('https://api.vercel.com/v2/user');

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Token validation timed out. Please check your connection and try again.',
            ),
          );

      if (response.statusCode == 200) {
        return TokenValidationStatus.valid;
      }

      // If checking user endpoint without teamId and Vercel returns 403 or 404,
      // the token may be scoped/fine-grained (e.g. project-scoped or personal token).
      // Check if it can read projects directly without specifying a team.
      if (!isTeamScoped &&
          (response.statusCode == 403 || response.statusCode == 404)) {
        try {
          final projectsResponse = await http
              .get(
                Uri.parse('https://api.vercel.com/v9/projects?limit=1'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 10));

          if (projectsResponse.statusCode == 200) {
            return TokenValidationStatus.valid;
          }
        } catch (_) {}

        // If projects request is also forbidden with 403, prompt for team scope
        if (response.statusCode == 403) {
          return TokenValidationStatus.teamScoped;
        }
      }

      return TokenValidationStatus.invalid;
    } catch (e) {
      if (kDebugMode) print('[AuthService] validateTokenDetails error: $e');
      return TokenValidationStatus.invalid;
    }
  }

  /// Validates a token against the account, or against a specific team when
  /// the token was created with team-only access.
  Future<bool> validateToken(String token, {String? teamId}) async {
    final status = await validateTokenDetails(token, teamId: teamId);
    return status == TokenValidationStatus.valid;
  }

  /// Fetch account details (user info) for a token
  Future<Map<String, dynamic>?> fetchAccountDetails(
    String token, {
    String? teamId,
  }) async {
    final normalizedTeamId = teamId?.trim();
    final isTeamScoped =
        normalizedTeamId != null && normalizedTeamId.isNotEmpty;

    try {
      // First try /www/user or /v2/user
      final userUri = Uri.parse('https://api.vercel.com/www/user');
      final response = await http
          .get(
            userUri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // For scoped/fine-grained tokens where user endpoint returns 403/404,
      // attempt to fetch project info to populate account metadata.
      try {
        final projectsUri = isTeamScoped
            ? Uri.parse('https://api.vercel.com/v9/projects').replace(
                queryParameters: {'teamId': normalizedTeamId, 'limit': '1'},
              )
            : Uri.parse('https://api.vercel.com/v9/projects?limit=1');

        final projectsResponse = await http
            .get(
              projectsUri,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (projectsResponse.statusCode == 200) {
          final pData =
              jsonDecode(projectsResponse.body) as Map<String, dynamic>;
          final projects = pData['projects'] as List<dynamic>?;
          if (projects != null && projects.isNotEmpty) {
            final first = projects.first as Map<String, dynamic>;
            final creator = first['creator'] as Map<String, dynamic>?;
            final accountId =
                first['accountId'] as String? ??
                (isTeamScoped ? 'team_$normalizedTeamId' : 'scoped_account');
            final username =
                creator?['username'] as String? ??
                creator?['githubLogin'] as String? ??
                (isTeamScoped
                    ? normalizedTeamId
                    : first['name'] as String? ?? 'Scoped Account');
            final name =
                creator?['username'] as String? ??
                first['name'] as String? ??
                (isTeamScoped ? 'Team: $normalizedTeamId' : 'Scoped Account');
            final email = creator?['email'] as String?;

            return {
              'user': {
                'id': creator?['uid']?.toString() ?? accountId,
                'username': username,
                'name': name,
                'email': email,
                'defaultTeamId': accountId.startsWith('team_')
                    ? accountId
                    : (isTeamScoped ? normalizedTeamId : null),
              },
            };
          }
        }
      } catch (_) {}

      // If team-scoped and user endpoint returns 403, construct basic details
      if (isTeamScoped) {
        return {
          'user': {
            'id': 'team_$normalizedTeamId',
            'username': normalizedTeamId,
            'name': 'Team: $normalizedTeamId',
            'email': null,
            'defaultTeamId': normalizedTeamId,
          },
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('[AuthService] fetchAccountDetails error: $e');
      return null;
    }
  }

  /// Migrate token from shared preferences to secure storage (legacy migration)
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_migrationKey) == true) return;

      final String? oldToken = prefs.getString(_tokenKey);
      if (oldToken != null && oldToken.isNotEmpty) {
        await _secureStorage.write(key: _tokenKey, value: oldToken);
        await prefs.remove(_tokenKey);
      }

      await prefs.setBool(_migrationKey, true);
    } catch (e) {
      // Ignored
    }
  }

  /// Migrate existing single-token storage to multi-account storage
  Future<void> _migrateToMultiAccount() async {
    try {
      final existingAccountsStr = await _secureStorage.read(key: _accountsKey);
      if (existingAccountsStr != null &&
          existingAccountsStr.trim().isNotEmpty) {
        return; // Already has multi-account storage
      }

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_multiAccountMigrationKey) == true) return;

      final legacyToken = await _secureStorage.read(key: _tokenKey);
      final legacyTeamScope = await _secureStorage.read(key: _teamScopeKey);

      if (legacyToken != null && legacyToken.trim().isNotEmpty) {
        if (kDebugMode) {
          print(
            '[AuthService] Migrating single account token to multi-account schema',
          );
        }

        // Try to fetch user info for richer account metadata
        Map<String, dynamic>? details;
        try {
          details = await fetchAccountDetails(
            legacyToken,
            teamId: legacyTeamScope,
          );
        } catch (_) {}

        final user = details?['user'] as Map<String, dynamic>?;
        final account = VercelAccount(
          id:
              user?['id']?.toString() ??
              'account_${DateTime.now().millisecondsSinceEpoch}',
          token: legacyToken.trim(),
          teamScope:
              (legacyTeamScope != null && legacyTeamScope.trim().isNotEmpty)
              ? legacyTeamScope.trim()
              : null,
          name:
              user?['name'] as String? ??
              user?['username'] as String? ??
              'Vercel Account',
          username: user?['username'] as String? ?? 'user',
          email: user?['email'] as String?,
          avatar: user?['avatar'] as String?,
          defaultTeamId: user?['defaultTeamId'] as String?,
          createdAt: DateTime.now(),
          isTeamScopedOnly:
              legacyTeamScope != null &&
              legacyTeamScope.isNotEmpty &&
              user == null,
        );

        final accounts = [account];
        final jsonStr = jsonEncode(accounts.map((a) => a.toJson()).toList());
        await _secureStorage.write(key: _accountsKey, value: jsonStr);
        await _secureStorage.write(key: _activeAccountIdKey, value: account.id);
      }

      await prefs.setBool(_multiAccountMigrationKey, true);
    } catch (e) {
      if (kDebugMode) print('[AuthService] _migrateToMultiAccount error: $e');
    }
  }

  /// Force migrate all existing tokens (useful for testing)
  Future<void> forceMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
    await prefs.remove(_multiAccountMigrationKey);
    await _migrateFromSharedPreferences();
    await _migrateToMultiAccount();
  }
}
