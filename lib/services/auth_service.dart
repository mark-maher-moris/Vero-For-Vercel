import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _tokenKey = 'vercel_access_token';
  static const String _migrationKey = 'migrated_to_secure_storage';
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<String?> getToken() async {
    // Try secure storage first
    String? token = await _secureStorage.read(key: _tokenKey);
    if (token != null) return token;
    
    // If not found, try to migrate from shared preferences
    await _migrateFromSharedPreferences();
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    
    // Mark migration as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
    
    // Also clear from shared preferences if it exists
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> validateToken(String token) async {
    final response = await http.get(
      Uri.parse('https://api.vercel.com/v2/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  /// Migrate token from shared preferences to secure storage
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if already migrated
      if (prefs.getBool(_migrationKey) == true) return;
      
      // Get token from shared preferences
      final String? oldToken = prefs.getString(_tokenKey);
      if (oldToken != null && oldToken.isNotEmpty) {
        // Move to secure storage
        await _secureStorage.write(key: _tokenKey, value: oldToken);
        
        // Remove from shared preferences
        await prefs.remove(_tokenKey);
        
        // Mark as migrated
        await prefs.setBool(_migrationKey, true);
        
        print('Successfully migrated API token to secure storage');
      }
    } catch (e) {
      print('Error during token migration: $e');
    }
  }

  /// Force migrate all existing tokens (useful for testing)
  Future<void> forceMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
    await _migrateFromSharedPreferences();
  }
}
