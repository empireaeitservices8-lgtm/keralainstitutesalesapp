import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_session.dart';

class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._internal();
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Save user session details
  Future<void> saveUserSession(UserSession session) async {
    final Map<String, String> data = session.toMap();
    final String jsonString = jsonEncode(data);
    await _storage.write(key: _userDataKey, value: jsonString);
  }

  /// Retrieve user session details
  Future<UserSession?> getUserSession() async {
    final String? jsonString = await _storage.read(key: _userDataKey);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final Map<String, String> map = decoded.map((key, value) => MapEntry(key, value.toString()));
      return UserSession.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Delete all stored credentials (logout)
  Future<void> clearAuthData() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
  }

  /// Delete everything from secure storage
  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }

  /// Write arbitrary value
  Future<void> writeValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read arbitrary value
  Future<String?> readValue(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete arbitrary value
  Future<void> deleteValue(String key) async {
    await _storage.delete(key: key);
  }
}
