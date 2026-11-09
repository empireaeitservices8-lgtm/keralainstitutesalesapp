import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../api/api_response.dart';
import 'home_provider.dart';
import 'user_profile_provider.dart';
import 'wallet_provider.dart';
import 'operations_provider.dart';
import 'attendance_provider.dart';

class AuthProvider extends ChangeNotifier {
  static final AuthProvider instance = AuthProvider._internal();
  AuthProvider._internal();

  UserSession _session = UserSession.empty();
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _requirePasswordChange = false;
  bool _isLoggingOut = false;
  bool _obscureConfirmPassword = true;

  UserSession get session => _session;
  bool get isLoading => _isLoading;
  bool get isBiometricLoading => _isBiometricLoading;
  bool get isLoggedIn => !_session.isEmpty;
  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
  bool get requirePasswordChange => _requirePasswordChange;
  bool get isLoggingOut => _isLoggingOut;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();
    
    final details = await AuthService.instance.getSessionDetails();
    _session = UserSession.fromMap(details);
    _requirePasswordChange = await AuthService.instance.hasPendingPasswordChange();
    
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
      _requirePasswordChange = await AuthService.instance.hasPendingPasswordChange();
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
      _requirePasswordChange = await AuthService.instance.hasPendingPasswordChange();
    }
    
    _isBiometricLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();

    final success = await AuthService.instance.changePassword(newPassword);
    if (success) {
      _requirePasswordChange = false;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String employeeId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await AuthService.instance.forgotPassword(
      employeeId: employeeId,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> deleteAccount({String? employeeId}) async {
    _isLoading = true;
    notifyListeners();

    final result = await AuthService.instance.deleteAccount(employeeId: employeeId);

    if (result['success'] == true) {
      await logout(callApi: false);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    return result;
  }

  void updateSessionRole(String newRole) {
    if (_session.role != newRole) {
      _session = UserSession(
        email: _session.email,
        authType: _session.authType,
        deviceToken: _session.deviceToken,
        name: _session.name,
        role: newRole,
        zone: _session.zone,
        district: _session.district,
        team: _session.team,
      );
      notifyListeners();
    }
  }

  void toggleObscureConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  Future<void> logout({bool callApi = true}) async {
    _isLoggingOut = true;
    notifyListeners();
    try {
      await AuthService.instance.logout(callApi: callApi);
      _session = UserSession.empty();
      _requirePasswordChange = false;
      
      // Reset all providers and current screen index on logout
      HomeProvider.instance.setCurrentIndex(0);
      HomeProvider.instance.setState(ApiResponse.empty());
      UserProfileProvider.instance.setState(ApiResponse.empty());
      WalletProvider.instance.setState(ApiResponse.empty());
      OperationsProvider.instance.clearData();
      AttendanceProvider.instance.clearData();
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }
}
