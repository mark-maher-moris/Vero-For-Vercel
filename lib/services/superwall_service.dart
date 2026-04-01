import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:superwallkit_flutter/superwallkit_flutter.dart' as sw;

/// Superwall Service - Manages paywall presentation and integrates with RevenueCat
/// 
/// This service uses RevenueCat as the purchase controller, allowing Superwall
/// to present paywalls while RevenueCat handles the actual purchasing logic.
class SuperwallService {
  static final SuperwallService _instance = SuperwallService._internal();
  factory SuperwallService() => _instance;
  SuperwallService._internal();

  /// Whether Superwall has been initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Get the appropriate Superwall API key based on platform
  String _getApiKey() {
    if (Platform.isIOS) {
      final key = dotenv.env['SUPERWALL_IOS_KEY'];
      if (key != null && key.isNotEmpty) return key;
    }
    
    if (Platform.isAndroid) {
      final key = dotenv.env['SUPERWALL_ANDROID_KEY'];
      if (key != null && key.isNotEmpty) return key;
    }
    
    // Fallback to generic key
    final key = dotenv.env['SUPERWALL_API_KEY'];
    if (key != null && key.isNotEmpty) return key;
    
    throw Exception(
      'Superwall API key not found. Please set SUPERWALL_IOS_KEY, '
      'SUPERWALL_ANDROID_KEY, or SUPERWALL_API_KEY in your .env file.'
    );
  }

  /// Initialize Superwall SDK with RevenueCat integration
  /// Call this in main.dart after RevenueCat is initialized
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) print('Superwall: Already initialized');
      return;
    }

    try {
      final apiKey = _getApiKey();
      
      // Create purchase controller that delegates to RevenueCat
      final purchaseController = RCPurchaseController();
      
      // Configure Superwall with RevenueCat purchase controller
      await sw.Superwall.configure(
        apiKey,
        purchaseController: purchaseController,
      );

      // Set up Superwall delegate to listen for events
      sw.Superwall.shared.setDelegate(_SuperwallDelegateImpl());

      _isInitialized = true;
      
      if (kDebugMode) {
        print('Superwall: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Superwall: Initialization error - $e');
      }
      rethrow;
    }
  }

  /// Identify user with Superwall
  /// Call this when user signs in
  Future<void> identify(String userId) async {
    if (!_isInitialized) {
      throw Exception('Superwall not initialized. Call initialize() first.');
    }
    
    try {
      await sw.Superwall.shared.identify(userId);
      if (kDebugMode) print('Superwall: Identified user $userId');
    } catch (e) {
      if (kDebugMode) print('Superwall: Identify error - $e');
      rethrow;
    }
  }

  /// Reset user identification
  /// Call this when user logs out
  Future<void> reset() async {
    if (!_isInitialized) return;
    
    try {
      await sw.Superwall.shared.reset();
      if (kDebugMode) print('Superwall: Reset user');
    } catch (e) {
      if (kDebugMode) print('Superwall: Reset error - $e');
    }
  }

  /// Set user attributes for targeting and personalization
  Future<void> setUserAttributes(Map<String, dynamic> attributes) async {
    if (!_isInitialized) return;
    
    try {
      // Convert dynamic map to Object map
      final objectMap = attributes.map((key, value) => MapEntry(key, value as Object));
      await sw.Superwall.shared.setUserAttributes(objectMap);
      if (kDebugMode) print('Superwall: Set user attributes');
    } catch (e) {
      if (kDebugMode) print('Superwall: Set attributes error - $e');
    }
  }

  /// Register a placement to potentially show a paywall
  /// 
  /// [placement] - The placement identifier configured in Superwall dashboard
  /// [params] - Optional parameters to pass to the paywall
  Future<void> registerPlacement(String placement, {Map<String, dynamic>? params}) async {
    if (!_isInitialized) {
      if (kDebugMode) print('Superwall: Not initialized, skipping placement $placement');
      return;
    }
    
    try {
      // Convert dynamic map to Object map if params provided
      final objectParams = params?.map((key, value) => MapEntry(key, value as Object));
      await sw.Superwall.shared.registerPlacement(placement, params: objectParams);
      if (kDebugMode) print('Superwall: Registered placement $placement');
    } catch (e) {
      if (kDebugMode) print('Superwall: Register placement error - $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    // Cleanup if needed
  }
}

/// Superwall Delegate Implementation
class _SuperwallDelegateImpl extends sw.SuperwallDelegate {
  @override
  void handleSuperwallEvent(sw.SuperwallEventInfo eventInfo) {
    if (kDebugMode) {
      print('Superwall: Event - ${eventInfo.event}');
    }
  }

  @override
  void willPresentPaywall(sw.PaywallInfo paywallInfo) {
    if (kDebugMode) {
      print('Superwall: Will present paywall - ${paywallInfo.identifier}');
    }
  }

  @override
  void didPresentPaywall(sw.PaywallInfo paywallInfo) {
    if (kDebugMode) {
      print('Superwall: Did present paywall - ${paywallInfo.identifier}');
    }
  }

  @override
  void willDismissPaywall(sw.PaywallInfo paywallInfo) {
    if (kDebugMode) {
      print('Superwall: Will dismiss paywall - ${paywallInfo.identifier}');
    }
  }

  @override
  void didDismissPaywall(sw.PaywallInfo paywallInfo) {
    if (kDebugMode) {
      print('Superwall: Did dismiss paywall - ${paywallInfo.identifier}');
    }
  }

  @override
  void handleLog(String title, String message, String? error, Map? info, String? logLevel) {
    if (kDebugMode) {
      print('Superwall Log [$logLevel]: $title - $message');
    }
  }

  @override
  void handleSuperwallDeepLink(Uri url, List<String> routingInfo, Map<String, String> additionalInfo) {
    if (kDebugMode) {
      print('Superwall Deep Link: $url');
    }
  }

  @override
  void paywallWillOpenDeepLink(Uri url) {
    if (kDebugMode) {
      print('Superwall Will Open Deep Link: $url');
    }
  }

  @override
  void paywallWillOpenURL(Uri url) {
    if (kDebugMode) {
      print('Superwall Will Open URL: $url');
    }
  }

  @override
  void handleCustomPaywallAction(String name) {
    if (kDebugMode) {
      print('Superwall Custom Action: $name');
    }
  }

  @override
  void subscriptionStatusDidChange(sw.SubscriptionStatus status) {
    if (kDebugMode) {
      print('Superwall: Subscription status changed to $status');
    }
  }
}

/// RevenueCat Purchase Controller for Superwall
/// 
/// This class implements the PurchaseController interface to delegate
/// all purchase operations to RevenueCat while keeping Superwall as
/// the paywall presentation layer.
class RCPurchaseController extends sw.PurchaseController {
  /// Configure RevenueCat and sync subscription status with Superwall
  /// This should be called before Superwall.configure()
  Future<void> configureAndSyncSubscriptionStatus() async {
    // RevenueCat is already configured in RevenueCatService
    // Just set up the listener for subscription status changes
    
    rc.Purchases.addCustomerInfoUpdateListener((customerInfo) async {
      // Convert RevenueCat entitlements to Superwall entitlements
      final entitlements = customerInfo.entitlements.active.keys
          .map((id) => sw.Entitlement(id: id))
          .toSet();

      final hasActiveEntitlementOrSubscription = 
          customerInfo.activeSubscriptions.isNotEmpty || 
          customerInfo.entitlements.active.isNotEmpty;

      if (hasActiveEntitlementOrSubscription) {
        await sw.Superwall.shared.setSubscriptionStatus(
          sw.SubscriptionStatusActive(entitlements: entitlements),
        );
      } else {
        await sw.Superwall.shared.setSubscriptionStatus(sw.SubscriptionStatusInactive());
      }
      
      if (kDebugMode) {
        print('Superwall: Subscription status updated - active: $hasActiveEntitlementOrSubscription');
      }
    });
  }

  /// Purchase from App Store via RevenueCat
  @override
  Future<sw.PurchaseResult> purchaseFromAppStore(String productId) async {
    try {
      // Get products from RevenueCat
      final products = await _getAllProducts([productId]);
      final storeProduct = products.firstOrNull;

      if (storeProduct == null) {
        return sw.PurchaseResult.failed('Failed to find store product for $productId');
      }

      return await _purchaseStoreProduct(storeProduct);
    } catch (e) {
      return sw.PurchaseResult.failed('Purchase error: $e');
    }
  }

  /// Purchase from Google Play via RevenueCat
  @override
  Future<sw.PurchaseResult> purchaseFromGooglePlay(
    String productId, 
    String? basePlanId, 
    String? offerId,
  ) async {
    try {
      final products = await _getAllProducts([productId]);
      
      // Find matching product for base plan
      final storeProductId = basePlanId != null ? '$productId:$basePlanId' : productId;
      rc.StoreProduct? matchingProduct;
      
      for (final product in products) {
        if (product.identifier == storeProductId) {
          matchingProduct = product;
          break;
        }
      }
      
      final storeProduct = matchingProduct ?? (products.isNotEmpty ? products.first : null);
      
      if (storeProduct == null) {
        return sw.PurchaseResult.failed('Product not found');
      }

      // Handle subscription vs non-subscription
      if (storeProduct.productCategory == rc.ProductCategory.subscription) {
        final subscriptionOptions = storeProduct.subscriptionOptions;
        if (subscriptionOptions != null && subscriptionOptions.isNotEmpty) {
          final optionId = _buildSubscriptionOptionId(basePlanId, offerId);
          
          rc.SubscriptionOption? subscriptionOption;
          for (final option in subscriptionOptions) {
            if (option.id == optionId) {
              subscriptionOption = option;
              break;
            }
          }
          subscriptionOption ??= storeProduct.defaultOption;
          
          if (subscriptionOption != null) {
            return await _purchaseSubscriptionOption(subscriptionOption);
          }
        }
        return sw.PurchaseResult.failed('No valid subscription option found');
      } else {
        return await _purchaseStoreProduct(storeProduct);
      }
    } catch (e) {
      return sw.PurchaseResult.failed('Purchase error: $e');
    }
  }

  /// Purchase a subscription option
  Future<sw.PurchaseResult> _purchaseSubscriptionOption(rc.SubscriptionOption subscriptionOption) async {
    return await _handleSharedPurchase(() async {
      final result = await rc.Purchases.purchaseSubscriptionOption(subscriptionOption);
      return result.customerInfo;
    });
  }

  /// Purchase a store product
  Future<sw.PurchaseResult> _purchaseStoreProduct(rc.StoreProduct storeProduct) async {
    return await _handleSharedPurchase(() async {
      final result = await rc.Purchases.purchaseStoreProduct(storeProduct);
      return result.customerInfo;
    });
  }

  /// Handle shared purchase logic
  Future<sw.PurchaseResult> _handleSharedPurchase(Future<rc.CustomerInfo> Function() performPurchase) async {
    try {
      final customerInfo = await performPurchase();
      
      if (customerInfo.activeSubscriptions.isNotEmpty || 
          customerInfo.entitlements.active.isNotEmpty) {
        return sw.PurchaseResult.purchased;
      } else {
        return sw.PurchaseResult.failed('No active subscriptions found');
      }
    } on PlatformException catch (e) {
      final errorCode = rc.PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == rc.PurchasesErrorCode.paymentPendingError) {
        return sw.PurchaseResult.pending;
      } else if (errorCode == rc.PurchasesErrorCode.purchaseCancelledError) {
        return sw.PurchaseResult.cancelled;
      } else {
        return sw.PurchaseResult.failed(e.message ?? 'Purchase failed');
      }
    }
  }

  /// Restore purchases via RevenueCat
  @override
  Future<sw.RestorationResult> restorePurchases() async {
    try {
      await rc.Purchases.restorePurchases();
      return sw.RestorationResult.restored;
    } on PlatformException catch (e) {
      return sw.RestorationResult.failed(e.message ?? 'Restore failed');
    }
  }

  /// Build subscription option ID from base plan and offer
  String _buildSubscriptionOptionId(String? basePlanId, String? offerId) {
    final parts = <String>[];
    if (basePlanId != null) parts.add(basePlanId);
    if (offerId != null) parts.add(offerId);
    return parts.join(':');
  }

  /// Get all products from RevenueCat
  Future<List<rc.StoreProduct>> _getAllProducts(List<String> productIdentifiers) async {
    final subscriptionProducts = await rc.Purchases.getProducts(
      productIdentifiers,
      productCategory: rc.ProductCategory.subscription,
    );
    final nonSubscriptionProducts = await rc.Purchases.getProducts(
      productIdentifiers,
      productCategory: rc.ProductCategory.nonSubscription,
    );
    return [...subscriptionProducts, ...nonSubscriptionProducts];
  }
}
