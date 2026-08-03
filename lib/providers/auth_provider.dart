import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static final AuthProvider instance = AuthProvider._internal();
  AuthProvider._internal();

  UserSession _session = UserSession.empty();
  bool _isLoading = false;
  bool _isBiometricLoading = false;

  UserSession get session => _session;
  bool get isLoading => _isLoading;
  bool get isBiometricLoading => _isBiometricLoading;
  bool get isLoggedIn => !_session.isEmpty;

  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();
    
    final details = await AuthService.instance.getSessionDetails();
    _session = UserSession.fromMap(details);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithEmail(String email, String password, bool rememberMe) async {
    _isLoading = true;
    notifyListeners();
    
    final success = await AuthService.instance.loginWithEmail(email, password, rememberMe);
    if (success) {
      final details = await AuthService.instance.getSessionDetails();
      _session = UserSession.fromMap(details);
    }
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> authenticateWithDevice() async {
    _isBiometricLoading = true;
    notifyListeners();
    
    final success = await AuthService.instance.authenticateWithDevice();
    if (success) {
      final details = await AuthService.instance.getSessionDetails();
      _session = UserSession.fromMap(details);
    }
    
    _isBiometricLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _session = UserSession.empty();
    notifyListeners();
  }
}
