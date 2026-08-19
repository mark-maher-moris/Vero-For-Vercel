import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service responsible for managing local push notifications on Android & iOS.
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService({FlutterLocalNotificationsPlugin? plugin}) {
    if (plugin != null) {
      return LocalNotificationService.custom(plugin);
    }
    return _instance;
  }
  static LocalNotificationService get instance => _instance;
  LocalNotificationService._internal() : _notificationsPlugin = FlutterLocalNotificationsPlugin();
  LocalNotificationService.custom(this._notificationsPlugin);
  LocalNotificationService.forTesting() : _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void Function(NotificationResponse notificationResponse)? _onNotificationTap;

  /// Set or update the notification tap callback at any time
  void setOnNotificationTap(void Function(NotificationResponse notificationResponse)? callback) {
    _onNotificationTap = callback;
  }

  static const String whatsNewChannelId = 'whats_new_channel';
  static const String whatsNewChannelName = "What's New Updates";
  static const String whatsNewChannelDescription =
      "Notifications announcing new features, updates, and improvements in Vero.";

  /// Retrieve the notification response if the app was launched by tapping a notification from a terminated state
  Future<NotificationResponse?> getNotificationAppLaunchDetails() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) {
      return null;
    }
    try {
      final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        return details.notificationResponse;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalNotificationService] getNotificationAppLaunchDetails error: $e');
      }
    }
    return null;
  }

  /// Initialize local notification settings for Android and iOS
  Future<void> initialize({
    void Function(NotificationResponse notificationResponse)? onNotificationTap,
  }) async {
    if (onNotificationTap != null) {
      _onNotificationTap = onNotificationTap;
    }
    if (_isInitialized) return;

    try {
      // Android Initialization Settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS / macOS Darwin Initialization Settings
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false, // We request explicitly via requestPermissions()
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        await _notificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (response) {
            if (kDebugMode) {
              print('[LocalNotificationService] Notification tapped: ${response.payload}');
            }
            if (_onNotificationTap != null) {
              _onNotificationTap!(response);
            }
          },
        );
      }

      // Create Android Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            whatsNewChannelId,
            whatsNewChannelName,
            description: whatsNewChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('[LocalNotificationService] Successfully initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalNotificationService] Initialization error: $e');
      }
    }
  }

  /// Request notification permissions on Android (13+) and iOS
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isIOS) {
        final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      } else if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[LocalNotificationService] requestPermissions error: $e');
      }
      return false;
    }
  }

  /// Display a local heads-up notification immediately
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        channelId ?? whatsNewChannelId,
        channelName ?? whatsNewChannelName,
        channelDescription: channelDescription ?? whatsNewChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        await _notificationsPlugin.show(
          id,
          title,
          body,
          notificationDetails,
          payload: payload,
        );
      }

      if (kDebugMode) {
        print('[LocalNotificationService] Shown notification: $title - $body (id: $id)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalNotificationService] showNotification error: $e');
      }
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all pending/active notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
