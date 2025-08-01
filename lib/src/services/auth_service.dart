import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  
  // Use secure storage for mobile and shared preferences for web
  static final _secureStorage = FlutterSecureStorage();
  static late final SharedPreferences? _prefs;
  
  // Initialize shared preferences for web
  static Future<void> init() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // Save the authentication token
  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      await _prefs?.setString(_tokenKey, token);
    } else {
      await _secureStorage.write(key: _tokenKey, value: token);
    }
    if (kDebugMode) {
      print('Token saved: ${token.substring(0, 10)}...');
    }
  }

  // Get the stored authentication token
  static Future<String?> getToken() async {
    try {
      final token = kIsWeb 
          ? _prefs?.getString(_tokenKey)
          : await _secureStorage.read(key: _tokenKey);
          
      if (kDebugMode) {
        print('Retrieved token: ${token != null ? '${token.substring(0, 10)}...' : 'null'}');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting token: $e');
      }
      return null;
    }
  }

  // Remove the authentication token (logout)
  static Future<void> deleteToken() async {
    if (kIsWeb) {
      await _prefs?.remove(_tokenKey);
    } else {
      await _secureStorage.delete(key: _tokenKey);
    }
    if (kDebugMode) {
      print('Token deleted');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final isLoggedIn = token != null && token.isNotEmpty;
    if (kDebugMode) {
      print('isLoggedIn: $isLoggedIn');
    }
    return isLoggedIn;
  }
}
