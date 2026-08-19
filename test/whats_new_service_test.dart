import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero/models/whats_new_message.dart';
import 'package:vero/services/local_notification_service.dart';
import 'package:vero/services/whats_new_service.dart';

class SpyLocalNotificationService extends LocalNotificationService {
  SpyLocalNotificationService() : super.forTesting();
  final List<Map<String, dynamic>> shownNotifications = [];

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {
    shownNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  @override
  Future<bool> requestPermissions() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WhatsNewMessage Model Tests', () {
    test('serializes and deserializes correctly', () {
      final message = WhatsNewMessage(
        id: 'test_msg_1',
        targetVersion: '1.4.0',
        title: 'New Feature Test',
        body: 'Testing notification description',
        isProOnly: true,
        isIosOnly: true,
        isAndroidOnly: false,
        payload: 'vero://test',
        releaseDate: DateTime(2026, 8, 19),
      );

      final json = message.toJson();
      expect(json['id'], 'test_msg_1');
      expect(json['targetVersion'], '1.4.0');
      expect(json['title'], 'New Feature Test');
      expect(json['body'], 'Testing notification description');
      expect(json['isProOnly'], true);
      expect(json['isIosOnly'], true);
      expect(json['isAndroidOnly'], false);
      expect(json['payload'], 'vero://test');
      expect(json['releaseDate'], isNotNull);

      final fromJson = WhatsNewMessage.fromJson(json);
      expect(fromJson.id, message.id);
      expect(fromJson.targetVersion, message.targetVersion);
      expect(fromJson.title, message.title);
      expect(fromJson.body, message.body);
      expect(fromJson.isProOnly, message.isProOnly);
      expect(fromJson.isIosOnly, message.isIosOnly);
      expect(fromJson.isAndroidOnly, message.isAndroidOnly);
      expect(fromJson.payload, message.payload);
      expect(fromJson.releaseDate, message.releaseDate);
    });

    test('serializes and deserializes isAndroidOnly correctly', () {
      final message = WhatsNewMessage(
        id: 'test_msg_android',
        targetVersion: '1.3.2',
        title: 'Android Only Feature',
        body: 'Home widgets for Android',
        isAndroidOnly: true,
      );

      final json = message.toJson();
      expect(json['isAndroidOnly'], true);
      expect(json['isIosOnly'], false);

      final fromJson = WhatsNewMessage.fromJson(json);
      expect(fromJson.isAndroidOnly, true);
      expect(fromJson.isIosOnly, false);
    });
  });

  group('WhatsNewService Core Rules Tests', () {
    late WhatsNewService service;
    late SpyLocalNotificationService spyNotificationService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      spyNotificationService = SpyLocalNotificationService();
      service = WhatsNewService(notificationService: spyNotificationService);
    });

    test('Rule 1: Users who just downloaded the app today receive NO notifications', () async {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime(2026, 8, 19, 10, 0, 0);

      // First run ever (simulating download today)
      final deliveredOnFirstRun = await service.checkAndDeliverWhatsNew(
        isProUser: true,
        customPrefs: prefs,
        customNow: today,
        customCurrentVersion: '1.3.2',
        customNotificationService: spyNotificationService,
      );

      expect(deliveredOnFirstRun, isEmpty,
          reason: 'Brand new downloads today must not receive What\'s New notifications.');
      expect(spyNotificationService.shownNotifications, isEmpty);

      // Second launch on the same day
      final deliveredOnSecondLaunchSameDay = await service.checkAndDeliverWhatsNew(
        isProUser: true,
        customPrefs: prefs,
        customNow: today.add(const Duration(hours: 3)),
        customCurrentVersion: '1.3.2',
        customNotificationService: spyNotificationService,
      );

      expect(deliveredOnSecondLaunchSameDay, isEmpty,
          reason: 'Same day subsequent launches must also be suppressed.');
      expect(spyNotificationService.shownNotifications, isEmpty);
    });

    test('Rule 2: Existing users updating the app on a subsequent day receive new What\'s New messages', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // User installed 9 days ago
      final installDate = DateTime(2026, 8, 10);
      await prefs.setString(WhatsNewService.keyFirstInstalledAt, installDate.toIso8601String());
      await prefs.setString(WhatsNewService.keyLastKnownVersion, '1.3.0');
      await prefs.setStringList(WhatsNewService.keySentNotificationIds, []);

      // Today the user updates to 1.3.2 (Pro user, on Android)
      final today = DateTime(2026, 8, 19);
      final delivered = await service.checkAndDeliverWhatsNew(
        isProUser: true,
        customPrefs: prefs,
        customNow: today,
        customCurrentVersion: '1.3.2',
        customNotificationService: spyNotificationService,
        customIsIos: false,
      );

      expect(delivered, isNotEmpty,
          reason: 'Existing users who update should receive available What\'s New notifications.');
      expect(spyNotificationService.shownNotifications.length, delivered.length);
      
      // Check that all delivered messages are now marked as sent in SharedPreferences
      final sentIds = prefs.getStringList(WhatsNewService.keySentNotificationIds) ?? [];
      for (final msg in delivered) {
        expect(sentIds.contains(msg.id), isTrue,
            reason: 'Each delivered message must be recorded in sent IDs.');
      }
    });

    test('Rule 3: Duplicate Prevention - Never send the same notification twice', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // User installed 5 days ago
      final installDate = DateTime(2026, 8, 14);
      await prefs.setString(WhatsNewService.keyFirstInstalledAt, installDate.toIso8601String());
      await prefs.setString(WhatsNewService.keyLastKnownVersion, '1.3.0');
      await prefs.setStringList(WhatsNewService.keySentNotificationIds, []);

      final today = DateTime(2026, 8, 19);
      
      // First update launch
      final firstDelivery = await service.checkAndDeliverWhatsNew(
        isProUser: true,
        customPrefs: prefs,
        customNow: today,
        customCurrentVersion: '1.3.2',
        customNotificationService: spyNotificationService,
      );
      expect(firstDelivery, isNotEmpty);
      final notificationCountFirstRun = spyNotificationService.shownNotifications.length;

      // Immediate next check
      final secondDelivery = await service.checkAndDeliverWhatsNew(
        isProUser: true,
        customPrefs: prefs,
        customNow: today.add(const Duration(minutes: 10)),
        customCurrentVersion: '1.3.2',
        customNotificationService: spyNotificationService,
      );
      expect(secondDelivery, isEmpty,
          reason: 'Already sent notifications must NEVER be sent again.');
      expect(spyNotificationService.shownNotifications.length, notificationCountFirstRun,
          reason: 'Notification count must remain identical.');
    });

    test('Rule 4: Pro-Only Targeting (isProOnly: true)', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // User installed 5 days ago
      final installDate = DateTime(2026, 8, 14);
      await prefs.setString(WhatsNewService.keyFirstInstalledAt, installDate.toIso8601String());
      await prefs.setString(WhatsNewService.keyLastKnownVersion, '1.3.0');
      await prefs.setStringList(WhatsNewService.keySentNotificationIds, []);

      // Register custom test messages with isProOnly: true and false
      final freeMsg = const WhatsNewMessage(
        id: 'test_free_msg',
        targetVersion: '1.3.2',
        title: 'Free Feature',
        body: 'For everyone',
        isProOnly: false,
      );
      final proMsg = const WhatsNewMessage(
        id: 'test_pro_msg',
        targetVersion: '1.3.2',
        title: 'Pro Feature',
        body: 'For Pro only',
        isProOnly: true,
      );
      service.registerMessage(freeMsg);
      service.registerMessage(proMsg);

      final today = DateTime(2026, 8, 19);

      // Scenario A: Non-Pro user launches app
      final freeDelivered = await service.checkAndDeliverWhatsNew(
        isProUser: false,
        customPrefs: prefs,
        customNow: today,
        customCurrentVersion: '1.3.2',
        customNotificationService: spyNotificationService,
      );

      expect(freeDelivered.any((m) => m.id == 'test_free_msg'), isTrue,
          reason: 'Free messages must be sent to non-Pro users.');
      expect(freeDelivered.any((m) => m.id == 'test_pro_msg'), isFalse,
          reason: 'Pro-only messages must NOT be sent to non-Pro users.');

      // Scenario B: User later subscribes to Pro
      final proDelivered = await service.checkAndDeliverWhatsNew(
        isProUser: true,
        customPrefs: prefs,
        customNow: today.add(const Duration(hours: 1)),
        customCurrentVersion: '1.3.2',
        customNotificationService: spyNotificationService,
      );

      expect(proDelivered.any((m) => m.id == 'test_pro_msg'), isTrue,
          reason: 'Pro-only messages should now be delivered to the new Pro subscriber.');
      expect(proDelivered.any((m) => m.id == 'test_free_msg'), isFalse,
          reason: 'Free message was already delivered and must not duplicate.');
    });

    test('Rule 5: Platform Targeting (isIosOnly vs isAndroidOnly)', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // User installed 5 days ago
      final installDate = DateTime(2026, 8, 14);
      await prefs.setString(WhatsNewService.keyFirstInstalledAt, installDate.toIso8601String());
      await prefs.setString(WhatsNewService.keyLastKnownVersion, '1.3.0');
      await prefs.setStringList(WhatsNewService.keySentNotificationIds, []);

      // Register custom test messages
      final bothPlatformsMsg = const WhatsNewMessage(
        id: 'test_both_platforms_msg',
        targetVersion: '1.3.2',
        title: 'Universal Feature',
        body: 'Available for both iOS and Android',
      );
      final iosOnlyMsg = const WhatsNewMessage(
        id: 'test_ios_only_msg',
        targetVersion: '1.3.2',
        title: 'iOS Exclusive Feature',
        body: 'Feature for iOS only',
        isIosOnly: true,
      );
      final androidOnlyMsg = const WhatsNewMessage(
        id: 'test_android_only_msg',
        targetVersion: '1.3.2',
        title: 'Android Exclusive Feature',
        body: 'Feature for Android only',
        isAndroidOnly: true,
      );
      service.registerMessage(bothPlatformsMsg);
      service.registerMessage(iosOnlyMsg);
      service.registerMessage(androidOnlyMsg);

      final today = DateTime(2026, 8, 19);

      // Scenario A: Android user checks for updates
      final androidDelivered = await service.checkAndDeliverWhatsNew(
        isProUser: true,
        customPrefs: prefs,
        customNow: today,
        customCurrentVersion: '1.3.2',
        customNotificationService: spyNotificationService,
        customIsIos: false, // Android platform
      );

      expect(androidDelivered.any((m) => m.id == 'test_both_platforms_msg'), isTrue,
          reason: 'Android receives universal messages.');
      expect(androidDelivered.any((m) => m.id == 'test_android_only_msg'), isTrue,
          reason: 'Android receives Android-only messages.');
      expect(androidDelivered.any((m) => m.id == 'test_ios_only_msg'), isFalse,
          reason: 'Android user must NOT receive iOS-only messages.');

      // Scenario B: iOS user checks for updates
      final iosPrefs = await SharedPreferences.getInstance();
      await iosPrefs.setString(WhatsNewService.keyFirstInstalledAt, installDate.toIso8601String());
      await iosPrefs.setString(WhatsNewService.keyLastKnownVersion, '1.3.0');
      await iosPrefs.setStringList(WhatsNewService.keySentNotificationIds, []);

      final iosSpyService = SpyLocalNotificationService();
      final iosService = WhatsNewService(notificationService: iosSpyService);
      iosService.registerMessage(bothPlatformsMsg);
      iosService.registerMessage(iosOnlyMsg);
      iosService.registerMessage(androidOnlyMsg);

      final iosDelivered = await iosService.checkAndDeliverWhatsNew(
        isProUser: true,
        customPrefs: iosPrefs,
        customNow: today,
        customCurrentVersion: '1.3.2',
        customNotificationService: iosSpyService,
        customIsIos: true, // iOS platform
      );

      expect(iosDelivered.any((m) => m.id == 'test_both_platforms_msg'), isTrue,
          reason: 'iOS receives universal messages.');
      expect(iosDelivered.any((m) => m.id == 'test_ios_only_msg'), isTrue,
          reason: 'iOS user must receive iOS-only messages.');
      expect(iosDelivered.any((m) => m.id == 'test_android_only_msg'), isFalse,
          reason: 'iOS user must NOT receive Android-only messages.');
    });

    test('Rule 6: Android and iOS default catalog delivers correct platform messages', () async {
      final androidPrefs = await SharedPreferences.getInstance();
      final installDate = DateTime(2026, 8, 10);
      await androidPrefs.setString(WhatsNewService.keyFirstInstalledAt, installDate.toIso8601String());
      await androidPrefs.setString(WhatsNewService.keyLastKnownVersion, '1.3.0');
      await androidPrefs.setStringList(WhatsNewService.keySentNotificationIds, []);

      final today = DateTime(2026, 8, 19);

      // 1. Android check
      final androidSpy = SpyLocalNotificationService();
      final androidDelivered = await service.checkAndDeliverWhatsNew(
        isProUser: false,
        customPrefs: androidPrefs,
        customNow: today,
        customCurrentVersion: '1.3.2',
        customNotificationService: androidSpy,
        customIsIos: false,
      );

      final androidIds = androidDelivered.map((m) => m.id).toSet();
      expect(androidIds.contains('whats_new_1_3_2_android_widgets'), isTrue,
          reason: 'Android user receives Android home widgets notification.');
      expect(androidIds.contains('whats_new_1_3_2_android_multi_account'), isTrue,
          reason: 'Android user receives Android multi-account notification.');
      expect(androidIds.contains('whats_new_1_3_2_ios_multi_account'), isFalse,
          reason: 'Android user does NOT receive iOS multi-account notification.');
      expect(androidIds.contains('whats_new_1_3_2_widgets'), isFalse,
          reason: 'Android user does NOT receive iOS widgets notification.');

      // 2. iOS check
      final iosPrefs = await SharedPreferences.getInstance();
      await iosPrefs.setString(WhatsNewService.keyFirstInstalledAt, installDate.toIso8601String());
      await iosPrefs.setString(WhatsNewService.keyLastKnownVersion, '1.3.0');
      await iosPrefs.setStringList(WhatsNewService.keySentNotificationIds, []);

      final iosSpy = SpyLocalNotificationService();
      final iosDelivered = await service.checkAndDeliverWhatsNew(
        isProUser: false,
        customPrefs: iosPrefs,
        customNow: today,
        customCurrentVersion: '1.3.2',
        customNotificationService: iosSpy,
        customIsIos: true,
      );

      final iosIds = iosDelivered.map((m) => m.id).toSet();
      expect(iosIds.contains('whats_new_1_3_2_ios_multi_account'), isTrue,
          reason: 'iOS user receives iOS multi-account notification.');
      expect(iosIds.contains('whats_new_1_3_2_widgets'), isTrue,
          reason: 'iOS user receives iOS widgets notification.');
      expect(iosIds.contains('whats_new_1_3_2_android_widgets'), isFalse,
          reason: 'iOS user does NOT receive Android widgets notification.');
      expect(iosIds.contains('whats_new_1_3_2_android_multi_account'), isFalse,
          reason: 'iOS user does NOT receive Android multi-account notification.');
    });
  });
}
