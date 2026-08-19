import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart' as sw;
import 'account_entitlement_policy.dart';

/// Superwall Service - Manages paywall presentation, in-app purchases, and analytics tracking
///
/// This service uses Superwall to:
/// 1. Present paywalls and handle purchases
/// 2. Track user behavior and analytics
/// 3. Set user attributes for segmentation
/// 4. Manage placements for funnel analysis
///
/// Superwall events are automatically tracked for:
/// - User identification
/// - Feature engagement
/// - Subscription events
/// - Custom user actions
class SuperwallService {
  static final SuperwallService _instance = SuperwallService._internal();
  factory SuperwallService() => _instance;
  SuperwallService._internal();

  /// Whether Superwall has been initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Stream controller for subscription status changes
  final _subscriptionController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStream => _subscriptionController.stream;

  /// Current subscription status
  bool _hasActiveSubscription = false;
  bool get hasActiveSubscription => _hasActiveSubscription;

  /// Get current subscription status directly from Superwall (async)
  Future<bool> getCurrentSubscriptionStatus() async {
    if (!_isInitialized) {
      if (kDebugMode)
        print(
          'Superwall: Not initialized, returning cached status: $_hasActiveSubscription',
        );
      return _hasActiveSubscription;
    }

    try {
      final activeEntitlementIds = await getActiveEntitlementIds();
      final isPro = activeEntitlementIds.contains(
        AccountEntitlementPolicy.proEntitlementId,
      );

      if (kDebugMode) {
        print('Superwall: Checking status...');
        print('  - Entitlements active: $activeEntitlementIds');
        print('  - Result isPro: $isPro');
        print('  - Previous status: $_hasActiveSubscription');
      }

      if (isPro != _hasActiveSubscription) {
        if (kDebugMode)
          print('Superwall: Status mismatch detected, updating to $isPro');
        _updateSubscriptionStatus(isPro);
      }

      return isPro;
    } catch (e) {
      if (kDebugMode)
        print('Superwall: Error checking subscription status: $e');
      return _hasActiveSubscription;
    }
  }

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
      'SUPERWALL_ANDROID_KEY, or SUPERWALL_API_KEY in your .env file.',
    );
  }

  /// Whether Superwall is currently initializing
  Completer<void>? _initCompleter;

  /// Initialize Superwall SDK
  /// Call this in main.dart before runApp()
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) print('Superwall: Already initialized');
      return;
    }

    if (_initCompleter != null) {
      if (kDebugMode)
        print('Superwall: Initialization already in progress, waiting...');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      final apiKey = _getApiKey();

      // Superwall.configure starts native configuration and returns the shared
      // instance synchronously. Wait for its completion callback before making
      // entitlement or placement calls.
      final configured = Completer<void>();
      sw.Superwall.configure(
        apiKey,
        completion: () {
          if (!configured.isCompleted) configured.complete();
        },
      );

      // Set up Superwall delegate to listen for events
      sw.Superwall.shared.setDelegate(_SuperwallDelegateImpl());

      try {
        await configured.future.timeout(const Duration(seconds: 10));
      } on TimeoutException {
        // Do not block app startup forever if the native SDK cannot complete
        // configuration. The SDK can still finish in the background.
        if (kDebugMode) {
          print('Superwall: Configuration callback timed out; continuing');
        }
      }

      _isInitialized = true;
      _initCompleter!.complete();

      if (kDebugMode) {
        print('Superwall: Initialized successfully');
      }
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      if (kDebugMode) {
        print('Superwall: Initialization error - $e');
      }
      rethrow;
    } finally {
      _initCompleter = null;
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
      _updateSubscriptionStatus(false);
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
      final objectMap = attributes.map(
        (key, value) => MapEntry(key, value as Object),
      );
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
  /// [ignoreActiveSubscription] - Set to true if placement is for an add-on or dedicated tier
  Future<void> registerPlacement(
    String placement, {
    Map<String, dynamic>? params,
    bool ignoreActiveSubscription = false,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode)
        print('Superwall: Not initialized, skipping placement $placement');
      return;
    }

    // Skip if user already has an active subscription unless explicitly allowed or it's a dedicated placement
    if (_hasActiveSubscription &&
        !ignoreActiveSubscription &&
        placement != 'connect_new_account') {
      if (kDebugMode)
        print(
          'Superwall: User has active subscription, skipping paywall placement $placement',
        );
      return;
    }

    try {
      // Convert dynamic map to Object map if params provided
      final objectParams = params?.map(
        (key, value) => MapEntry(key, value as Object),
      );

      if (kDebugMode) print('Superwall: Registering placement $placement');

      await sw.Superwall.shared.registerPlacement(
        placement,
        params: objectParams,
      );

      if (kDebugMode)
        print('Superwall: Successfully registered placement $placement');
    } catch (e) {
      if (kDebugMode) print('Superwall: Register placement error - $e');
    }
  }

  /// Register a placement with full result tracking. The caller must still
  /// verify the exact entitlement after this presentation result.
  Future<bool> registerGatedPlacement(
    String placement, {
    Map<String, dynamic>? params,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode)
        print(
          'Superwall: Not initialized, cannot check gated placement $placement',
        );
      return false;
    }

    final completer = Completer<bool>();
    final handler = sw.PaywallPresentationHandler();

    void safeComplete(bool result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    handler.onDismiss((paywallInfo, paywallResult) {
      if (kDebugMode)
        print('Superwall onDismiss for $placement: $paywallResult');
      if (paywallResult is sw.PurchasedPaywallResult ||
          paywallResult is sw.RestoredPaywallResult) {
        safeComplete(true);
      } else {
        safeComplete(false);
      }
    });

    handler.onSkip((reason) {
      if (kDebugMode) print('Superwall onSkip for $placement: $reason');
      // A skip means no paywall was shown (holdout, no audience match, or a
      // missing placement). It is never proof that an add-on was purchased.
      safeComplete(false);
    });

    handler.onError((error) {
      if (kDebugMode) print('Superwall onError for $placement: $error');
      safeComplete(false);
    });

    try {
      final objectParams = params?.map(
        (key, value) => MapEntry(key, value as Object),
      );
      if (kDebugMode)
        print('Superwall: Registering gated placement $placement');

      await sw.Superwall.shared.registerPlacement(
        placement,
        params: objectParams,
        handler: handler,
        feature: () {
          if (kDebugMode)
            print('Superwall feature callback unlocked for $placement');
          safeComplete(true);
        },
      );
    } catch (e) {
      if (kDebugMode)
        print('Superwall: Error registering gated placement $placement - $e');
      safeComplete(false);
    }

    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        if (kDebugMode) {
          print('Superwall: Timed out waiting for gated placement $placement');
        }
        return false;
      },
    );
  }

  /// Trigger placement specifically for connecting a new account and wait for actual unlock/purchase
  Future<bool> registerConnectAccountPlacement({
    int currentAccountCount = 1,
  }) async {
    return await registerGatedPlacement(
      'connect_new_account',
      params: {
        'account_count': currentAccountCount,
        'action': 'connect_new_account',
      },
    );
  }

  /// Present a paywall manually
  Future<void> presentPaywall() async {
    if (!_isInitialized) {
      if (kDebugMode)
        print('Superwall: Not initialized, cannot present manual paywall');
      return;
    }

    if (_hasActiveSubscription) {
      if (kDebugMode)
        print(
          'Superwall: User has active subscription, skipping manual paywall',
        );
      return;
    }

    try {
      if (kDebugMode) print('Superwall: Presenting manual paywall');
      // Register a generic placement to trigger paywall presentation
      await sw.Superwall.shared.registerPlacement('manual_paywall');
      if (kDebugMode) print('Superwall: Successfully triggered manual paywall');
    } catch (e) {
      if (kDebugMode) print('Superwall: Present paywall error - $e');
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isInitialized) return;

    try {
      await sw.Superwall.shared.restorePurchases();
      if (kDebugMode) print('Superwall: Restore purchases called');
    } catch (e) {
      if (kDebugMode) print('Superwall: Restore purchases error - $e');
    }
  }

  /// Track a custom analytics event (pure analytics, no paywall trigger)
  ///
  /// This uses a dedicated analytics placement that should be configured
  /// in Superwall dashboard to NOT trigger paywalls.
  ///
  /// [eventName] - The event name to track
  /// [properties] - Optional event properties
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized) return;

    try {
      final params = <String, Object>{
        'event_name': eventName,
        if (properties != null)
          ...properties.map((key, value) => MapEntry(key, value as Object)),
      };

      // Use 'analytics' placement - configure this in Superwall dashboard
      // to NOT show paywalls (for pure analytics tracking only)
      await sw.Superwall.shared.registerPlacement('analytics', params: params);

      if (kDebugMode) {
        print('Superwall: Tracked event - $eventName');
      }
    } catch (e) {
      if (kDebugMode) print('Superwall: Track event error - $e');
    }
  }

  /// Track screen view
  ///
  /// [screenName] - The name of the screen
  /// [additionalProps] - Additional properties
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? additionalProps,
  }) async {
    await trackEvent(
      'screen_view',
      properties: {'screen_name': screenName, ...?additionalProps},
    );
  }

  /// Track user action
  ///
  /// [action] - The action name
  /// [context] - Context where the action occurred
  Future<void> trackUserAction(
    String action, {
    String? context,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'user_action',
      properties: {
        'action': action,
        if (context != null) 'context': context,
        ...?properties,
      },
    );
  }

  /// Track feature usage
  ///
  /// [featureName] - The feature being used
  /// [isProFeature] - Whether this is a pro feature
  Future<void> trackFeatureUsage(
    String featureName, {
    bool isProFeature = false,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'feature_usage',
      properties: {
        'feature_name': featureName,
        'is_pro_feature': isProFeature,
        ...?properties,
      },
    );
  }

  /// Track deployment action
  Future<void> trackDeploymentAction(
    String action,
    String projectId, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'deployment_action',
      properties: {'action': action, 'project_id': projectId, ...?properties},
    );
  }

  /// Track project action
  Future<void> trackProjectAction(
    String action, {
    String? projectId,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'project_action',
      properties: {
        'action': action,
        if (projectId != null) 'project_id': projectId,
        ...?properties,
      },
    );
  }

  /// Track subscription-related event
  Future<void> trackSubscriptionEvent(
    String eventType, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'subscription_$eventType',
      properties: {'event_type': eventType, ...?properties},
    );
  }

  /// Track error events
  Future<void> trackError(
    String errorType,
    String message, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'error',
      properties: {
        'error_type': errorType,
        'error_message': message,
        ...?properties,
      },
    );
  }

  /// Update subscription status internally
  void _updateSubscriptionStatus(bool hasActiveSubscription) {
    _hasActiveSubscription = hasActiveSubscription;
    _subscriptionController.add(hasActiveSubscription);
  }

  /// Get the current Superwall user ID (support ID)
  Future<String> getUserId() async {
    if (!_isInitialized) return '';
    try {
      return await sw.Superwall.shared.getUserId();
    } catch (e) {
      if (kDebugMode) print('Superwall: Get userId error - $e');
      return '';
    }
  }

  /// Get user entitlements from Superwall
  Future<sw.Entitlements> getEntitlements() async {
    if (!_isInitialized)
      return sw.Entitlements(active: {}, inactive: {}, all: {}, web: {});
    try {
      return await sw.Superwall.shared.getEntitlements();
    } catch (e) {
      if (kDebugMode) print('Superwall: Get entitlements error - $e');
      return sw.Entitlements(active: {}, inactive: {}, all: {}, web: {});
    }
  }

  /// Return the IDs of currently active, non-revoked entitlements.
  Future<Set<String>> getActiveEntitlementIds() async {
    final entitlements = await getEntitlements();
    return entitlements.active
        .where((entitlement) => entitlement.isActive)
        .map((entitlement) => entitlement.id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Check one exact entitlement. Do not use "any active entitlement" for
  /// product access because the add-on and Pro are separate products.
  Future<bool> hasEntitlement(String entitlementId) async {
    final normalizedId = entitlementId.trim().toLowerCase();
    if (normalizedId.isEmpty) return false;
    final activeIds = await getActiveEntitlementIds();
    return activeIds.contains(normalizedId);
  }

  /// Get customer info from Superwall (contains subscriptions with product data)
  Future<sw.CustomerInfo> getCustomerInfo() async {
    if (!_isInitialized) {
      return sw.CustomerInfo(
        subscriptions: [],
        nonSubscriptions: [],
        entitlements: [],
        userId: '',
      );
    }
    try {
      return await sw.Superwall.shared.getCustomerInfo();
    } catch (e) {
      if (kDebugMode) print('Superwall: Get customer info error - $e');
      return sw.CustomerInfo(
        subscriptions: [],
        nonSubscriptions: [],
        entitlements: [],
        userId: '',
      );
    }
  }

  /// Dispose of resources
  void dispose() {
    _subscriptionController.close();
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
  void handleLog(
    String title,
    String message,
    String? error,
    Map? info,
    String? logLevel,
  ) {
    if (kDebugMode) {
      print('Superwall Log [$logLevel]: $title - $message');
    }
  }

  @override
  void handleSuperwallDeepLink(
    Uri url,
    List<String> routingInfo,
    Map<String, String> additionalInfo,
  ) {
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
      print(
        'Superwall: Subscription status changed to $status (isActive: ${status.isActive})',
      );
    }

    // Check entitlements whenever status changes to ensure 'pro' is correctly identified
    SuperwallService().getCurrentSubscriptionStatus();
  }
}
