import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/superwall_service.dart';
import 'app_state.dart';

/// Provider for managing subscription state in the app
/// Uses Provider pattern for reactive UI updates
class SubscriptionProvider extends ChangeNotifier {
  final SuperwallService _superwallService = SuperwallService();
  final AppState? _appState;
  
  // State
  bool _isLoading = false;
  bool _isPro = false;
  String? _errorMessage;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isPro => _isPro || (_appState?.isDemoMode ?? false);
  String? get errorMessage => _errorMessage;
  
  // Computed properties for UI
  bool get hasActiveSubscription => _isPro;
  bool get hasError => _errorMessage != null;
  
  StreamSubscription<bool>? _subscriptionStatusSubscription;

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

      // Listen to subscription status updates from Superwall
      _subscriptionStatusSubscription = _superwallService.subscriptionStream.listen(
        _onSubscriptionStatusUpdate,
        onError: (error) {
          if (kDebugMode) {
            print('SubscriptionProvider: Subscription stream error - $error');
          }
        },
      );
      
      // Check initial subscription status (async to get latest)
      // This will now check entitlements internally
      _isPro = await _superwallService.getCurrentSubscriptionStatus();
      
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
    final isPro = await _superwallService.getCurrentSubscriptionStatus();
    _isPro = isPro;
    
    if (kDebugMode) {
      print('SubscriptionProvider: Pro status updated to $_isPro (received: $hasActiveSubscription)');
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
      _isPro = await _superwallService.getCurrentSubscriptionStatus();
      
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
      return _isPro;
    } catch (e) {
      _setError('Failed to show paywall: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register placement and potentially show paywall
  Future<bool> registerPlacement(String placement, {Map<String, dynamic>? params}) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _superwallService.registerPlacement(placement, params: params);
      return _isPro;
    } catch (e) {
      _setError('Failed to register placement: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _superwallService.restorePurchases();
      
      // Refresh after restore
      await refresh();
      return _isPro;
    } catch (e) {
      _setError('Failed to restore purchases: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sync user login with Superwall
  Future<void> onUserLogin(String userId) async {
    try {
      await _superwallService.identify(userId);
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
      await _superwallService.reset();
      _isPro = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('SubscriptionProvider: Logout sync error - $e');
      }
    }
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
