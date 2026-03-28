import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';

/// Provider for managing subscription state in the app
/// Uses Provider pattern for reactive UI updates
class SubscriptionProvider extends ChangeNotifier {
  final RevenueCatService _revenueCatService = RevenueCatService();
  
  // State
  bool _isLoading = false;
  bool _isPro = false;
  String? _errorMessage;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isPro => _isPro;
  String? get errorMessage => _errorMessage;
  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;
  
  // Product getters
  Package? get monthlyPackage => _offerings.monthlyPackage;
  Package? get yearlyPackage => _offerings.yearlyPackage;
  Package? get lifetimePackage => _offerings.lifetimePackage;
  
  // Computed properties for UI
  bool get hasActiveSubscription => _isPro;
  bool get hasError => _errorMessage != null;
  bool get hasOfferings => _offerings?.current != null;
  
  /// Entitlement details
  EntitlementInfo? get proEntitlementInfo => 
      _customerInfo?.entitlements.all[kVeroProEntitlement];
  
  DateTime? get proExpirationDate {
    final info = proEntitlementInfo;
    if (info == null) return null;
    final expiration = info.expirationDate;
    if (expiration == null) return null;
    return DateTime.tryParse(expiration);
  }
  
  bool get willRenew => proEntitlementInfo?.willRenew ?? false;
  String? get proPurchaseDate => proEntitlementInfo?.originalPurchaseDate?.toString();
  
  StreamSubscription<CustomerInfo>? _customerInfoSubscription;

  SubscriptionProvider() {
    _init();
  }

  /// Initialize the provider
  Future<void> _init() async {
    _setLoading(true);
    
    try {
      // Listen to customer info updates
      _customerInfoSubscription = _revenueCatService.customerInfoStream.listen(
        _onCustomerInfoUpdate,
        onError: (error) {
          if (kDebugMode) {
            print('SubscriptionProvider: Customer info stream error - $error');
          }
        },
      );
      
      // Load initial data
      await refresh();
    } catch (e) {
      _setError('Failed to initialize subscriptions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Handle customer info updates from RevenueCat
  void _onCustomerInfoUpdate(CustomerInfo info) {
    _customerInfo = info;
    final newProStatus = info.hasVeroPro;
    
    if (newProStatus != _isPro) {
      _isPro = newProStatus;
      if (kDebugMode) {
        print('SubscriptionProvider: Pro status changed to $_isPro');
      }
      notifyListeners();
    }
    
    _errorMessage = null;
  }

  /// Refresh subscription data
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Refresh offerings
      await _revenueCatService.fetchOfferings();
      _offerings = _revenueCatService.offerings;
      
      // Refresh customer info
      _customerInfo = await _revenueCatService.getCustomerInfo();
      _isPro = _customerInfo?.hasVeroPro ?? false;
      
      if (kDebugMode) {
        print('SubscriptionProvider: Refreshed - Pro: $_isPro');
      }
    } catch (e) {
      _setError('Failed to refresh subscription data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Purchase a specific package
  Future<bool> purchasePackage(Package package) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _revenueCatService.purchasePackage(package);
      
      if (result != null) {
        _isPro = result.hasVeroPro;
        _customerInfo = result;
        notifyListeners();
        return true;
      }
      
      return false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      
      // Handle specific error codes
      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          // User cancelled - not an error
          break;
        case PurchasesErrorCode.productAlreadyPurchasedError:
          _setError('You have already purchased this item. Try restoring purchases.');
          break;
        case PurchasesErrorCode.storeProblemError:
          _setError('There was a problem with the store. Please try again later.');
          break;
        case PurchasesErrorCode.purchaseNotAllowedError:
          _setError('Purchases are not allowed on this device.');
          break;
        case PurchasesErrorCode.paymentPendingError:
          _setError('Payment is pending. It may take a few minutes to process.');
          break;
        default:
          _setError('Purchase failed: ${e.message}');
      }
      
      return false;
    } catch (e) {
      _setError('Purchase failed: $e');
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
      final result = await _revenueCatService.restorePurchases();
      _isPro = result.hasVeroPro;
      _customerInfo = result;
      
      notifyListeners();
      return _isPro;
    } catch (e) {
      _setError('Failed to restore purchases: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Present the RevenueCat Paywall
  Future<bool> showPaywall() async {
    final result = await _revenueCatService.presentPaywall();
    
    // Refresh data after paywall is dismissed
    await refresh();
    return result;
  }

  /// Present the RevenueCat Paywall if user doesn't have Pro
  Future<bool> showPaywallIfNeeded() async {
    final result = await _revenueCatService.presentPaywallIfNeeded(kVeroProEntitlement);
    
    // Refresh data after paywall is dismissed
    await refresh();
    return result;
  }

  /// Present the Customer Center
  Future<void> showCustomerCenter() async {
    await _revenueCatService.presentCustomerCenter();
    
    // Refresh data after customer center is dismissed
    await refresh();
  }

  /// Check if user can make purchases
  Future<bool> checkCanMakePurchases() async {
    return await _revenueCatService.canMakePayments();
  }

  /// Sync user login with RevenueCat
  Future<void> onUserLogin(String userId) async {
    try {
      await _revenueCatService.login(userId);
      await refresh();
    } catch (e) {
      if (kDebugMode) {
        print('SubscriptionProvider: Login sync error - $e');
      }
    }
  }

  /// Sync user logout with RevenueCat
  Future<void> onUserLogout() async {
    try {
      await _revenueCatService.logout();
      _isPro = false;
      _customerInfo = null;
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
    _customerInfoSubscription?.cancel();
    super.dispose();
  }
}
