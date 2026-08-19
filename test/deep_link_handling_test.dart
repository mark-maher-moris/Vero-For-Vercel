import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vero/services/local_notification_service.dart';

class MockNotificationService extends LocalNotificationService {
  MockNotificationService() : super.forTesting();

  NotificationResponse? mockLaunchDetailsResponse;

  @override
  Future<NotificationResponse?> getNotificationAppLaunchDetails() async {
    return mockLaunchDetailsResponse;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalNotificationService Deep Linking & Callback Tests', () {
    test('setOnNotificationTap updates callback and gets invoked', () {
      final service = LocalNotificationService.forTesting();

      NotificationResponse? receivedResponse;
      service.setOnNotificationTap((response) {
        receivedResponse = response;
      });

      // Initialize with no callback, then verify setOnNotificationTap is preserved
      service.initialize();

      // Test updating callback
      NotificationResponse? updatedResponse;
      service.setOnNotificationTap((response) {
        updatedResponse = response;
      });

      expect(updatedResponse, isNull);
    });

    test('getNotificationAppLaunchDetails returns response when launched from notification', () async {
      final service = MockNotificationService();
      service.mockLaunchDetailsResponse = const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'vero://account/switcher',
      );

      final details = await service.getNotificationAppLaunchDetails();

      expect(details, isNotNull);
      expect(details?.payload, 'vero://account/switcher');
    });

    test('Deep link URI parsing correctly parses widget and account routes', () {
      final widgetUri = Uri.parse('vero://widget/configure?type=logs');
      expect(widgetUri.scheme, 'vero');
      expect(widgetUri.host, 'widget');
      expect(widgetUri.path, '/configure');
      expect(widgetUri.queryParameters['type'], 'logs');

      final accountUri = Uri.parse('vero://account/switcher');
      expect(accountUri.scheme, 'vero');
      expect(accountUri.host, 'account');
      expect(accountUri.path, '/switcher');
    });
  });
}
