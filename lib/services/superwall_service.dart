import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart' as sw;

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

  /// Initialize Superwall SDK
  /// Call this in main.dart before runApp()
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) print('Superwall: Already initialized');
      return;
    }

    try {
      final apiKey = _getApiKey();
      
      // Configure Superwall without external purchase controller
      // Superwall handles all purchase logic internally
      await sw.Superwall.configure(apiKey);

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
  /// [skipIfOnboardingIncomplete] - If true, skips showing paywall if onboarding is not complete
  Future<void> registerPlacement(String placement, {Map<String, dynamic>? params, bool skipIfOnboardingIncomplete = true}) async {
    if (!_isInitialized) {
      if (kDebugMode) print('Superwall: Not initialized, skipping placement $placement');
      return;
    }

    // Check if onboarding is complete before showing paywall
    if (skipIfOnboardingIncomplete) {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
      if (!hasCompletedOnboarding) {
        if (kDebugMode) print('Superwall: Skipping placement $placement - onboarding not complete');
        return;
      }
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

  /// Present a paywall manually
  Future<void> presentPaywall({bool skipIfOnboardingIncomplete = true}) async {
    if (!_isInitialized) return;

    // Check if onboarding is complete before showing paywall
    if (skipIfOnboardingIncomplete) {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
      if (!hasCompletedOnboarding) {
        if (kDebugMode) print('Superwall: Skipping manual paywall - onboarding not complete');
        return;
      }
    }
    
    try {
      // Register a generic placement to trigger paywall presentation
      await sw.Superwall.shared.registerPlacement('manual_paywall');
      if (kDebugMode) print('Superwall: Presented manual paywall');
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
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? properties}) async {
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
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? additionalProps}) async {
    await trackEvent('screen_view', properties: {
      'screen_name': screenName,
      ...?additionalProps,
    });
  }

  /// Track user action
  /// 
  /// [action] - The action name
  /// [context] - Context where the action occurred
  Future<void> trackUserAction(String action, {String? context, Map<String, dynamic>? properties}) async {
    await trackEvent('user_action', properties: {
      'action': action,
      if (context != null) 'context': context,
      ...?properties,
    });
  }

  /// Track feature usage
  /// 
  /// [featureName] - The feature being used
  /// [isProFeature] - Whether this is a pro feature
  Future<void> trackFeatureUsage(String featureName, {bool isProFeature = false, Map<String, dynamic>? properties}) async {
    await trackEvent('feature_usage', properties: {
      'feature_name': featureName,
      'is_pro_feature': isProFeature,
      ...?properties,
    });
  }

  /// Track deployment action
  Future<void> trackDeploymentAction(String action, String projectId, {Map<String, dynamic>? properties}) async {
    await trackEvent('deployment_action', properties: {
      'action': action,
      'project_id': projectId,
      ...?properties,
    });
  }

  /// Track project action
  Future<void> trackProjectAction(String action, {String? projectId, Map<String, dynamic>? properties}) async {
    await trackEvent('project_action', properties: {
      'action': action,
      if (projectId != null) 'project_id': projectId,
      ...?properties,
    });
  }

  /// Track subscription-related event
  Future<void> trackSubscriptionEvent(String eventType, {Map<String, dynamic>? properties}) async {
    await trackEvent('subscription_$eventType', properties: {
      'event_type': eventType,
      ...?properties,
    });
  }

  /// Track error events
  Future<void> trackError(String errorType, String message, {Map<String, dynamic>? properties}) async {
    await trackEvent('error', properties: {
      'error_type': errorType,
      'error_message': message,
      ...?properties,
    });
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
    
    // Update internal subscription status based on Superwall's status
    SuperwallService()._updateSubscriptionStatus(status.isActive);
  }
}
