import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/whats_new_message.dart';
import 'local_notification_service.dart';

/// Service that coordinates "What's New" feature announcements via Local Notifications.
///
/// Rules handled automatically:
/// 1. Only sends notifications on app updates (never sends to users who downloaded the app today).
/// 2. Tracks sent notification IDs to ensure each message is only sent once.
/// 3. Supports Pro-only targeting (`isProOnly: true` -> Pro users only; `isProOnly: false` -> All users).
class WhatsNewService {
  static final WhatsNewService _instance = WhatsNewService._internal();
  factory WhatsNewService({LocalNotificationService? notificationService}) {
    if (notificationService != null) {
      _instance._notificationService = notificationService;
    }
    return _instance;
  }
  WhatsNewService._internal();

  LocalNotificationService _notificationService = LocalNotificationService();

  static const String keyFirstInstalledAt = 'whats_new_first_installed_at';
  static const String keySentNotificationIds = 'whats_new_sent_notification_ids';
  static const String keyLastKnownVersion = 'whats_new_last_known_version';

  /// Catalog of "What's New" release announcements.
  /// You can add new version announcements here.
  final List<WhatsNewMessage> _catalog = [
    const WhatsNewMessage(
      id: 'whats_new_1_3_2_widgets',
      targetVersion: '1.3.2',
      title: "New Home Screen Widgets! 📱",
      body: "Track live visitor stats, traffic by country, and deployment logs directly from your home screen.",
      isProOnly: false,
      isIosOnly: true,
      payload: 'vero://widget/configure',
    ),
    const WhatsNewMessage(
      id: 'whats_new_1_3_2_android_widgets',
      targetVersion: '1.3.2',
      title: "New Home Screen Widgets! 📱",
      body: "Track live visitor stats, traffic analytics, and deployment logs directly from your Android home screen.",
      isProOnly: false,
      isAndroidOnly: true,
      payload: 'vero://widget/configure',
    ),
    const WhatsNewMessage(
      id: 'whats_new_1_3_2_android_multi_account',
      targetVersion: '1.3.2',
      title: "Connect Multiple Accounts ⚡️",
      body: "You can now connect and switch between multiple Vercel accounts seamlessly without logging out.",
      isProOnly: false,
      isAndroidOnly: true,
      payload: 'vero://account/switcher',
    ),
    const WhatsNewMessage(
      id: 'whats_new_1_3_2_ios_multi_account',
      targetVersion: '1.3.2',
      title: "Multi-Account Support ⚡️",
      body: "You can now connect multiple Vercel accounts instead of just one! Switch between all your accounts and teams effortlessly.",
      isProOnly: false,
      isIosOnly: true,
      payload: 'vero://account/switcher',
    ),
    const WhatsNewMessage(
      id: 'whats_new_1_4_0_custom_domains',
      targetVersion: '1.4.0',
      title: "What's New: Advanced DNS Management 🌐",
      body: "Inspect SSL certificates, manage custom domains, and check DNS propagation records on the fly.",
      isProOnly: false,
    ),
  ];

  /// Get the currently registered list of What's New messages
  List<WhatsNewMessage> get catalog => List.unmodifiable(_catalog);

  /// Register custom or new What's New messages dynamically
  void registerMessage(WhatsNewMessage message) {
    if (!_catalog.any((m) => m.id == message.id)) {
      _catalog.add(message);
    }
  }

  /// Register multiple What's New messages
  void registerMessages(List<WhatsNewMessage> messages) {
    for (final message in messages) {
      registerMessage(message);
    }
  }

  /// Evaluates and delivers any pending What's New notifications.
  ///
  /// [isProUser]: Pass whether the current user has an active Pro subscription.
  /// [customPrefs]: Optional SharedPreferences instance (useful for unit tests).
  /// [customNow]: Optional current timestamp (useful for unit tests).
  /// [customCurrentVersion]: Optional version override (useful for unit tests).
  /// [customNotificationService]: Optional LocalNotificationService override (useful for unit tests).
  /// [customIsIos]: Optional iOS platform override (useful for unit tests).
  Future<List<WhatsNewMessage>> checkAndDeliverWhatsNew({
    required bool isProUser,
    SharedPreferences? customPrefs,
    DateTime? customNow,
    String? customCurrentVersion,
    LocalNotificationService? customNotificationService,
    bool? customIsIos,
  }) async {
    final prefs = customPrefs ?? await SharedPreferences.getInstance();
    final now = customNow ?? DateTime.now();
    final notifier = customNotificationService ?? _notificationService;
    final isIosPlatform = customIsIos ?? (defaultTargetPlatform == TargetPlatform.iOS);

    // 1. Resolve current app version
    String currentVersion = customCurrentVersion ?? '1.0.0';
    if (customCurrentVersion == null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      } catch (e) {
        if (kDebugMode) {
          print('[WhatsNewService] Error fetching package info: $e');
        }
      }
    }

    // 2. Check first download / installation state
    final isFirstDay = await _handleFirstInstallCheck(prefs, now, currentVersion);
    if (isFirstDay) {
      if (kDebugMode) {
        print('[WhatsNewService] User installed app today or for the first time. Skipping What\'s New notifications.');
      }
      return [];
    }

    // 3. Retrieve already sent message IDs
    final sentIds = (prefs.getStringList(keySentNotificationIds) ?? []).toSet();

    // 4. Find all eligible unsent notifications
    final deliveredMessages = <WhatsNewMessage>[];

    for (final message in _catalog) {
      // Rule A: Never send same notification twice
      if (sentIds.contains(message.id)) {
        continue;
      }

      // Rule B: Check Pro-only targeting flag
      if (message.isProOnly && !isProUser) {
        if (kDebugMode) {
          print('[WhatsNewService] Skipping Pro-only message "${message.id}" for non-pro user.');
        }
        continue;
      }

      // Rule C: Check Platform targeting flag (isIosOnly / isAndroidOnly)
      if (message.isIosOnly && !isIosPlatform) {
        if (kDebugMode) {
          print('[WhatsNewService] Skipping iOS-only message "${message.id}" on non-iOS platform.');
        }
        continue;
      }
      if (message.isAndroidOnly && isIosPlatform) {
        if (kDebugMode) {
          print('[WhatsNewService] Skipping Android-only message "${message.id}" on iOS platform.');
        }
        continue;
      }

      // Rule D: Dispatch local notification
      final notificationId = message.id.hashCode.abs() % 100000;
      await notifier.showNotification(
        id: notificationId,
        title: message.title,
        body: message.body,
        payload: message.payload,
      );

      // Mark as sent immediately to avoid race conditions or duplicates
      sentIds.add(message.id);
      deliveredMessages.add(message);

      if (kDebugMode) {
        print('[WhatsNewService] Delivered notification: ${message.title} (ID: ${message.id}, ProOnly: ${message.isProOnly}, IosOnly: ${message.isIosOnly}, AndroidOnly: ${message.isAndroidOnly})');
      }
    }

    // 5. Persist updated sent IDs and last known version
    await prefs.setStringList(keySentNotificationIds, sentIds.toList());
    await prefs.setString(keyLastKnownVersion, currentVersion);

    return deliveredMessages;
  }

  /// Checks whether today is the user's first download day.
  /// If it is the first time the app is launched ever, records the install timestamp
  /// and marks all current catalog messages as sent so they won't trigger later on day 1.
  Future<bool> _handleFirstInstallCheck(
    SharedPreferences prefs,
    DateTime now,
    String currentVersion,
  ) async {
    final firstInstalledStr = prefs.getString(keyFirstInstalledAt);

    if (firstInstalledStr == null) {
      // First time launch ever: record install date and current version
      await prefs.setString(keyFirstInstalledAt, now.toIso8601String());
      await prefs.setString(keyLastKnownVersion, currentVersion);

      // Mark all current catalog messages as already seen/sent so new users
      // starting today are not spammed with past release notifications
      final initialSentIds = _catalog.map((m) => m.id).toList();
      await prefs.setStringList(keySentNotificationIds, initialSentIds);

      return true;
    }

    final firstInstalledDate = DateTime.tryParse(firstInstalledStr);
    if (firstInstalledDate == null) {
      await prefs.setString(keyFirstInstalledAt, now.toIso8601String());
      return true;
    }

    // Check if install date is on the exact same calendar day
    final isSameCalendarDay = now.year == firstInstalledDate.year &&
        now.month == firstInstalledDate.month &&
        now.day == firstInstalledDate.day;

    return isSameCalendarDay;
  }

  /// Check if a specific notification ID has already been sent
  Future<bool> isNotificationSent(String id, {SharedPreferences? customPrefs}) async {
    final prefs = customPrefs ?? await SharedPreferences.getInstance();
    final sentIds = prefs.getStringList(keySentNotificationIds) ?? [];
    return sentIds.contains(id);
  }

  /// Forcefully send a specific What's New notification for testing/debug purposes
  Future<bool> testSendNotification(
    String messageId, {
    required bool isProUser,
    bool? customIsIos,
  }) async {
    final message = _catalog.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception('Message with ID $messageId not found in catalog.'),
    );

    if (message.isProOnly && !isProUser) {
      if (kDebugMode) {
        print('[WhatsNewService] Cannot send Pro-only test notification to non-pro user.');
      }
      return false;
    }

    final isIosPlatform = customIsIos ?? (defaultTargetPlatform == TargetPlatform.iOS);
    if (message.isIosOnly && !isIosPlatform) {
      if (kDebugMode) {
        print('[WhatsNewService] Skipping iOS-only test notification on non-iOS platform.');
      }
      return false;
    }
    if (message.isAndroidOnly && isIosPlatform) {
      if (kDebugMode) {
        print('[WhatsNewService] Skipping Android-only test notification on iOS platform.');
      }
      return false;
    }

    final notificationId = message.id.hashCode.abs() % 100000;
    await _notificationService.showNotification(
      id: notificationId,
      title: message.title,
      body: message.body,
      payload: message.payload,
    );

    return true;
  }

  /// Reset history in SharedPreferences (useful for QA / debug testing)
  Future<void> resetNotificationHistory({SharedPreferences? customPrefs}) async {
    final prefs = customPrefs ?? await SharedPreferences.getInstance();
    await prefs.remove(keyFirstInstalledAt);
    await prefs.remove(keySentNotificationIds);
    await prefs.remove(keyLastKnownVersion);
  }
}
