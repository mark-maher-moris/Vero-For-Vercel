import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat API Keys - Loaded from environment variables
/// REVENUECAT_APPLE_KEY: iOS/macOS App Store API key
/// REVENUECAT_ANDROID_KEY: Google Play API key  
/// REVENUECAT_TEST_KEY: Sandbox/testing API key (fallback)

/// Entitlement ID for Vero Pro
const String kVeroProEntitlement = 'Vero Pro';

/// Product identifiers for different subscription types
class ProductIds {
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';
  static const String lifetime = 'lifetime';
}

/// Singleton service for managing RevenueCat subscriptions
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  /// Stream controller for customer info updates
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  /// Current customer info
  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  /// Current offerings
  Offerings? _offerings;
  Offerings? get offerings => _offerings;

  /// Whether user has Vero Pro entitlement
  bool get hasProEntitlement {
    if (_customerInfo == null) return false;
    return _customerInfo!.entitlements.active.containsKey(kVeroProEntitlement);
  }

  /// Initialize RevenueCat SDK
  /// Call this in main.dart before runApp()
  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final configuration = PurchasesConfiguration(_getApiKey());
      
      await Purchases.configure(configuration);

      // Set up listener for customer info updates
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _customerInfoController.add(customerInfo);
        if (kDebugMode) {
          print('RevenueCat: Customer info updated');
          print('Entitlements: ${customerInfo.entitlements.active.keys}');
        }
      });

      // Fetch initial customer info
      _customerInfo = await Purchases.getCustomerInfo();
      
      // Fetch offerings
      await fetchOfferings();

      if (kDebugMode) {
        print('RevenueCat: Initialized successfully');
        print('Pro entitlement: $hasProEntitlement');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Initialization error - $e');
      }
      rethrow;
    }
  }

  /// Get the appropriate API key based on platform from environment variables
  String _getApiKey() {
    // Try to get platform-specific key first
    if (Platform.isIOS || Platform.isMacOS) {
      final appleKey = dotenv.env['REVENUECAT_APPLE_KEY'];
      if (appleKey != null && appleKey.isNotEmpty) {
        if (kDebugMode) print('RevenueCat: Using Apple API key');
        return appleKey;
      }
    }
    
    if (Platform.isAndroid) {
      final androidKey = dotenv.env['REVENUECAT_ANDROID_KEY'];
      if (androidKey != null && androidKey.isNotEmpty) {
        if (kDebugMode) print('RevenueCat: Using Android API key');
        return androidKey;
      }
    }
    
    // Fall back to test key for development
    final testKey = dotenv.env['REVENUECAT_TEST_KEY'];
    if (testKey != null && testKey.isNotEmpty) {
      if (kDebugMode) print('RevenueCat: Using test API key');
      return testKey;
    }
    
    // If no keys are configured, throw an error
    throw Exception(
      'RevenueCat API key not found. Please set REVENUECAT_APPLE_KEY, '
      'REVENUECAT_ANDROID_KEY, or REVENUECAT_TEST_KEY in your .env file.'
    );
  }

  /// Fetch available offerings from RevenueCat
  Future<void> fetchOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      if (kDebugMode) {
        if (_offerings?.current != null) {
          print('RevenueCat: Offerings fetched successfully');
          final packages = _offerings!.current!.availablePackages;
          for (final pkg in packages) {
            print('Package: ${pkg.identifier} - ${pkg.storeProduct.priceString}');
          }
        } else {
          print('RevenueCat: No offerings available');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Error fetching offerings - $e');
      }
      rethrow;
    }
  }

  /// Present the RevenueCat Paywall
  /// Returns true if a purchase was made, false otherwise
  Future<bool> presentPaywall() async {
    try {
      final paywallResult = await RevenueCatUI.presentPaywall();
      
      if (kDebugMode) {
        print('RevenueCat: Paywall result - ${paywallResult.toString()}');
      }
      
      // Check if user has pro entitlement after paywall
      return hasProEntitlement;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Paywall error - $e');
      }
      return false;
    }
  }

  /// Present the RevenueCat Paywall if needed (only if no active subscription)
  Future<bool> presentPaywallIfNeeded(String entitlementIdentifier) async {
    try {
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(entitlementIdentifier);
      
      if (kDebugMode) {
        print('RevenueCat: Conditional paywall result - ${paywallResult.toString()}');
      }
      
      return hasProEntitlement;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Conditional paywall error - $e');
      }
      return false;
    }
  }

  /// Present the Customer Center for subscription management
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
      
      if (kDebugMode) {
        print('RevenueCat: Customer Center presented');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Customer Center error - $e');
      }
      rethrow;
    }
  }

  /// Purchase a specific package
  /// Returns the customer info after purchase
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      
      // Update customer info from result
      _customerInfo = result.customerInfo;
      
      if (kDebugMode) {
        print('RevenueCat: Purchase successful - ${package.identifier}');
      }
      
      return result.customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      
      if (kDebugMode) {
        print('RevenueCat: Purchase error - ${e.message} (Code: $errorCode)');
      }
      
      // Handle specific error codes
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // User cancelled - not an error
        return null;
      }
      
      rethrow;
    }
  }

  /// Restore purchases from previous device or account
  /// Returns the restored customer info
  Future<CustomerInfo> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      
      if (kDebugMode) {
        print('RevenueCat: Purchases restored');
        print('Entitlements: ${customerInfo.entitlements.active.keys}');
      }
      
      return customerInfo;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Restore error - $e');
      }
      rethrow;
    }
  }

  /// Get current customer info
  /// Use this to check entitlements in real-time
  Future<CustomerInfo> getCustomerInfo() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _customerInfo = customerInfo;
      return customerInfo;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Get customer info error - $e');
      }
      rethrow;
    }
  }

  /// Identify user with a unique app user ID
  /// Call this after user logs in
  Future<void> login(String userId) async {
    try {
      final loginResult = await Purchases.logIn(userId);
      _customerInfo = loginResult.customerInfo;
      
      if (kDebugMode) {
        print('RevenueCat: User logged in - $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Login error - $e');
      }
      rethrow;
    }
  }

  /// Log out current user and reset to anonymous
  /// Call this when user logs out
  Future<void> logout() async {
    try {
      // Check if user is anonymous - if so, skip logout to avoid error
      final userId = _customerInfo?.originalAppUserId;
      if (userId == null || userId.startsWith('\$RCAnonymousID:')) {
        if (kDebugMode) {
          print('RevenueCat: User is anonymous, skipping logout');
        }
        return;
      }
      
      final customerInfo = await Purchases.logOut();
      _customerInfo = customerInfo;
      
      if (kDebugMode) {
        print('RevenueCat: User logged out');
      }
    } on PlatformException catch (e) {
      // Handle the specific case where logout was called on anonymous user
      if (e.code == '22' || 
          e.message?.contains('anonymous') == true ||
          e.details?.toString().contains('LOGOUT_CALLED_WITH_ANONYMOUS_USER') == true) {
        if (kDebugMode) {
          print('RevenueCat: User is anonymous, logout not needed');
        }
        return;
      }
      if (kDebugMode) {
        print('RevenueCat: Logout error - $e');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Logout error - $e');
      }
      rethrow;
    }
  }

  /// Sync customer attributes with RevenueCat
  Future<void> setAttributes(Map<String, String> attributes) async {
    try {
      await Purchases.setAttributes(attributes);
      
      if (kDebugMode) {
        print('RevenueCat: Attributes set - $attributes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Set attributes error - $e');
      }
      rethrow;
    }
  }

  /// Sync purchase with RevenueCat (for promotions, etc.)
  Future<void> syncPurchases() async {
    try {
      await Purchases.syncPurchases();
      
      if (kDebugMode) {
        print('RevenueCat: Purchases synced');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Sync purchases error - $e');
      }
      rethrow;
    }
  }

  /// Check if user can make payments (not restricted by parental controls, etc.)
  Future<bool> canMakePayments() async {
    try {
      return await Purchases.canMakePayments();
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Can make payments check error - $e');
      }
      return false;
    }
  }

  /// Get promotional offer for a product (iOS only)
  Future<PromotionalOffer?> getPromotionalOffer(
    StoreProduct product,
    StoreProductDiscount discount,
  ) async {
    if (!Platform.isIOS) return null;
    
    try {
      return await Purchases.getPromotionalOffer(product, discount);
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Get promotional offer error - $e');
      }
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _customerInfoController.close();
  }
}

/// Extension methods for easier access to product information
extension OfferingsExtension on Offerings? {
  /// Get the current offering's monthly package
  Package? get monthlyPackage {
    final current = this?.current;
    if (current == null) return null;
    
    return current.monthly ??
        current.availablePackages.firstWhere(
          (p) => p.packageType == PackageType.monthly,
          orElse: () => current.availablePackages.firstWhere(
            (p) => p.identifier.toLowerCase().contains('monthly'),
            orElse: () => current.availablePackages.first,
          ),
        );
  }

  /// Get the current offering's yearly package
  Package? get yearlyPackage {
    final current = this?.current;
    if (current == null) return null;
    
    return current.annual ??
        current.availablePackages.firstWhere(
          (p) => p.packageType == PackageType.annual,
          orElse: () => current.availablePackages.firstWhere(
            (p) => p.identifier.toLowerCase().contains('yearly') ||
                   p.identifier.toLowerCase().contains('annual'),
            orElse: () => current.availablePackages.first,
          ),
        );
  }

  /// Get the current offering's lifetime package
  Package? get lifetimePackage {
    final current = this?.current;
    if (current == null) return null;
    
    return current.lifetime ??
        current.availablePackages.firstWhere(
          (p) => p.packageType == PackageType.lifetime,
          orElse: () => current.availablePackages.firstWhere(
            (p) => p.identifier.toLowerCase().contains('lifetime'),
            orElse: () => current.availablePackages.first,
          ),
        );
  }
}

/// Extension for CustomerInfo to easily check entitlements
extension CustomerInfoExtension on CustomerInfo {
  /// Check if user has Vero Pro entitlement
  bool get hasVeroPro => entitlements.active.containsKey(kVeroProEntitlement);
  
  /// Get the expiration date for Vero Pro entitlement
  EntitlementInfo? get veroProInfo => entitlements.all[kVeroProEntitlement];
  
  /// Check if Vero Pro will renew
  bool get willRenewVeroPro => veroProInfo?.willRenew ?? false;
  
  /// Get Vero Pro expiration date
  DateTime? get veroProExpirationDate {
    final expiration = veroProInfo?.expirationDate;
    if (expiration == null) return null;
    return DateTime.tryParse(expiration);
  }
  
  /// Check if Vero Pro was purchased
  bool get hasPurchasedVeroPro => entitlements.all.containsKey(kVeroProEntitlement);
}
