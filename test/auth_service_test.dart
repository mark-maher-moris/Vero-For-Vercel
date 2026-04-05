import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lib/services/auth_service.dart';

void main() {
  group('AuthService Migration Tests', () {
    late AuthService authService;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    test('should migrate token from shared preferences to secure storage', () async {
      // Set up old token in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vercel_access_token', 'test_token_123');

      // Get token - should trigger migration
      final token = await authService.getToken();

      // Token should be retrieved successfully
      expect(token, equals('test_token_123'));

      // Verify token is now in secure storage
      final secureToken = await authService.getToken();
      expect(secureToken, equals('test_token_123'));

      // Verify old token is removed from shared preferences
      final oldToken = prefs.getString('vercel_access_token');
      expect(oldToken, isNull);
    });

    test('should not migrate if already migrated', () async {
      // Set up migration flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('migrated_to_secure_storage', true);
      await prefs.setString('vercel_access_token', 'old_token');

      // Get token - should not migrate
      final token = await authService.getToken();

      // Should return null since no token in secure storage
      expect(token, isNull);

      // Old token should still exist in shared preferences
      final oldToken = prefs.getString('vercel_access_token');
      expect(oldToken, equals('old_token'));
    });

    test('should handle empty shared preferences gracefully', () async {
      // Get token with no existing token
      final token = await authService.getToken();

      // Should return null
      expect(token, isNull);
    });

    test('should save new token to secure storage', () async {
      // Save new token
      await authService.saveToken('new_token_456');

      // Retrieve token
      final token = await authService.getToken();

      // Should return the new token
      expect(token, equals('new_token_456'));
    });

    test('should delete token from both storage locations', () async {
      // Set up token in both locations
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vercel_access_token', 'old_token');
      await authService.saveToken('secure_token');

      // Delete token
      await authService.deleteToken();

      // Should be null from secure storage
      final secureToken = await authService.getToken();
      expect(secureToken, isNull);

      // Should be removed from shared preferences
      final oldToken = prefs.getString('vercel_access_token');
      expect(oldToken, isNull);
    });
  });
}
