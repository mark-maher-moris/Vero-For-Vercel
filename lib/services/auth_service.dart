import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'vercel_access_token';
  static const String _refreshTokenKey = 'vercel_refresh_token';

  // Integration markers for user to fill in
  static const String clientId = 'cl_0MTgwuq7H4XfsAztxxn8dn2ef27WnPJ4';
  static const String clientSecret =
      'e3722eb43304b728e9f49d4566820da3be053bd51830417e21f37102fc55c519';
  static const String redirectUri = 'https://vero-server.vercel.app/callback';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token, {String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> loginWithVercel() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateRandomString(16);

    final url = Uri.https('vercel.com', '/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'response_type': 'code',
      'scope': 'openid email profile offline_access',
    });

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'com.buildagon.vero',
      );

      final callbackUri = Uri.parse(result);
      final code = callbackUri.queryParameters['code'];
      final returnedState = callbackUri.queryParameters['state'];

      if (state != returnedState) {
        throw Exception('State mismatch');
      }

      if (code != null) {
        await _exchangeCodeForToken(code, codeVerifier);
      } else {
        throw Exception('No authorization code returned');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _exchangeCodeForToken(String code, String codeVerifier) async {
    final response = await http.post(
      Uri.parse('https://api.vercel.com/login/oauth/token'),
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'code_verifier': codeVerifier,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveToken(
        data['access_token'],
        refreshToken: data['refresh_token'],
      );
    } else {
      final error = json.decode(response.body);
      throw Exception(
        'Failed to exchange code: ${error['error_description'] ?? error['error']}',
      );
    }
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(
      values,
    ).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(
      digest.bytes,
    ).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  String _generateRandomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (i) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
