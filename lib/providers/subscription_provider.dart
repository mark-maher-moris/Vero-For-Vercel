import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/superwall_service.dart';
import '../services/account_entitlement_policy.dart';
import 'app_state.dart';

/// Provider for managing subscription state in the app
/// Uses Provider pattern for reactive UI updates
class SubscriptionProvider extends ChangeNotifier {
  final SuperwallService _superwallService = SuperwallService();
  final AppState? _appState;

  // State
  bool _isLoading = false;
  bool _isPro = false;
  bool _hasAdditionalAccountEntitlement = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isPro => _isPro || (_appState?.isDemoMode ?? false);
  bool get hasProEntitlement => _isPro;
  bool get hasAdditionalAccountEntitlement => _hasAdditionalAccountEntitlement;
  String? get errorMessage => _errorMessage;

  // Computed properties for UI
  bool get hasActiveSubscription => _isPro;
  bool get hasError => _errorMessage != null;

  StreamSubscription<bool>? _subscriptionStatusSubscription;
  Future<bool>? _additionalAccountAuthorization;

  SubscriptionProvider({AppState? appState}) : _appState = appState {
    _init();
  }

  /// Initialize the provider
  Future<void> _init() async {
    _setLoading(true);

    try {
      // Ensure Superwall is initialized before proceeding
      if (!_superwallService.isInitialized) {
        await _superwallService.initialize();
      }

      // Entitlements must be loaded for the stable app-level billing identity,
      // not for whichever Vercel account happens to be active.
      if (_appState != null) {
        await _appState.syncBillingIdentity();
      }

      // Listen to subscription status updates from Superwall
      _subscriptionStatusSubscription = _superwallService.subscriptionStream
          .listen(
            _onSubscriptionStatusUpdate,
            onError: (error) {
              if (kDebugMode) {
                print(
                  'SubscriptionProvider: Subscription stream error - $error',
                );
              }
            },
          );

      // Check initial entitlements (async to get latest).
      await _refreshEntitlements();

      if (kDebugMode) {
        print('SubscriptionProvider: Initial Pro status: $_isPro');
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize subscriptions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Handle subscription status updates from Superwall
  void _onSubscriptionStatusUpdate(bool hasActiveSubscription) async {
    // Re-verify the status to ensure entitlements are checked
    await _refreshEntitlements();

    if (kDebugMode) {
      print(
        'SubscriptionProvider: Pro status updated to $_isPro (received: $hasActiveSubscription)',
      );
    }

    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh subscription data
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();

    try {
      // Update subscription status from Superwall (async to get latest)
      await _refreshEntitlements();

      if (kDebugMode) {
        print('SubscriptionProvider: Refreshed - Pro: $_isPro');
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh subscription data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Present Superwall paywall for manual purchase
  Future<bool> showPaywall() async {
    _setLoading(true);
    _clearError();

    try {
      await _superwallService.presentPaywall();

      // Refresh data after paywall is dismissed
      await refresh();
      return hasProEntitlement;
    } catch (e) {
      _setError('Failed to show paywall: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register placement and potentially show paywall
  Future<bool> registerPlacement(
    String placement, {
    Map<String, dynamic>? params,
    bool ignoreActiveSubscription = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _superwallService.registerPlacement(
        placement,
        params: params,
        ignoreActiveSubscription: ignoreActiveSubscription,
      );
      return _isPro;
    } catch (e) {
      _setError('Failed to register placement: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Trigger paywall flow specifically for connecting an additional account
  Future<bool> showConnectAccountPaywall({int currentAccountCount = 1}) async {
    if (!AccountEntitlementPolicy.canStartAdditionalAccount(
      accountCount: currentAccountCount,
    )) {
      _setError(
        currentAccountCount >= AccountEntitlementPolicy.maxConnectedAccounts
            ? 'You can connect a maximum of ${AccountEntitlementPolicy.maxConnectedAccounts} Vercel accounts.'
            : 'Connect your first Vercel account before adding another one.',
      );
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      if (!hasProEntitlement) {
        final hasPro = await showPaywall();
        if (!hasPro || !hasProEntitlement) return false;
      }

      if (hasAdditionalAccountEntitlement) return true;

      final unlocked = await _superwallService.registerConnectAccountPlacement(
        currentAccountCount: currentAccountCount,
      );
      // The handler result is only a presentation result. The exact
      // entitlement is the source of truth, including for restore/skip cases.
      await refresh();
      return unlocked &&
          AccountEntitlementPolicy.canUseAdditionalAccount(
            accountCount: currentAccountCount,
            hasProEntitlement: hasProEntitlement,
            hasAdditionalAccountEntitlement: hasAdditionalAccountEntitlement,
          );
    } catch (e) {
      _setError('Failed to present connect account paywall: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Authorize the additional-account flow before navigation or token work.
  /// This is intentionally safe to call more than once: an already-owned
  /// add-on returns immediately without showing another paywall.
  Future<bool> authorizeAdditionalAccount({int currentAccountCount = 1}) async {
    final inFlight = _additionalAccountAuthorization;
    if (inFlight != null) return inFlight;

    final authorization = _authorizeAdditionalAccount(
      currentAccountCount: currentAccountCount,
    );
    _additionalAccountAuthorization = authorization;
    authorization.then(
      (_) {
        if (identical(_additionalAccountAuthorization, authorization)) {
          _additionalAccountAuthorization = null;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_additionalAccountAuthorization, authorization)) {
          _additionalAccountAuthorization = null;
        }
      },
    );
    return authorization;
  }

  Future<bool> _authorizeAdditionalAccount({
    required int currentAccountCount,
  }) async {
    if (!AccountEntitlementPolicy.canStartAdditionalAccount(
      accountCount: currentAccountCount,
    )) {
      _setError(
        currentAccountCount >= AccountEntitlementPolicy.maxConnectedAccounts
            ? 'You can connect a maximum of ${AccountEntitlementPolicy.maxConnectedAccounts} Vercel accounts.'
            : 'Connect your first Vercel account before adding another one.',
      );
      return false;
    }

    if (!hasProEntitlement) {
      final hasPro = await showPaywall();
      if (!hasPro || !hasProEntitlement) return false;
    }

    if (hasAdditionalAccountEntitlement) return true;

    return showConnectAccountPaywall(currentAccountCount: currentAccountCount);
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    _setLoading(true);
    _clearError();

    try {
      await _superwallService.restorePurchases();

      // Refresh after restore
      await refresh();
      return hasProEntitlement;
    } catch (e) {
      _setError('Failed to restore purchases: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sync user login with Superwall
  Future<void> onUserLogin(String billingUserId) async {
    try {
      await _superwallService.identify(billingUserId);
      await refresh();
    } catch (e) {
      if (kDebugMode) {
        print('SubscriptionProvider: Login sync error - $e');
      }
    }
  }

  /// Sync user logout with Superwall
  Future<void> onUserLogout() async {
    try {
      // Vero currently has no separate app account. Disconnecting Vercel must
      // not erase the stable billing identity or hide purchases on reconnect.
      if (_appState != null) {
        await _appState.syncBillingIdentity();
      }
      await refresh();
    } catch (e) {
      if (kDebugMode) {
        print('SubscriptionProvider: Logout sync error - $e');
      }
    }
  }

  Future<void> _refreshEntitlements() async {
    final activeIds = await _superwallService.getActiveEntitlementIds();
    _isPro = activeIds.contains(AccountEntitlementPolicy.proEntitlementId);
    _hasAdditionalAccountEntitlement = activeIds.contains(
      AccountEntitlementPolicy.additionalAccountEntitlementId,
    );
  }

  /// Set loading state
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscriptionStatusSubscription?.cancel();
    super.dispose();
  }
}
