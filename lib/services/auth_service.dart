import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/exceptions/api_exception.dart';
import '../storage/secure_storage_service.dart';
import '../models/user_session.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Keys for SharedPreferences
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyAuthType = 'auth_type';
  static const String _keyDeviceToken = 'device_token';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserZone = 'user_zone';
  static const String _keyUserDistrict = 'user_district';
  static const String _keyUserTeam = 'user_team';
  static const String _keyRequirePasswordChange = 'require_password_change';

  // Preconfigured roles database for Kerala Institute Sales App SFA
  static const Map<String, Map<String, String>> mockUsers = {
    'md@keralainstitute.org': {
      'name': 'Dr. K. Kurian',
      'role': 'MD',
      'zone': '',
      'district': '',
      'team': '',
    },
    'zm.south@keralainstitute.org': {
      'name': 'Thomas Mathew',
      'role': 'ZM',
      'zone': 'South Zone',
      'district': '',
      'team': '',
    },
    'zm.central@keralainstitute.org': {
      'name': 'Sandhya Nair',
      'role': 'ZM',
      'zone': 'Central Zone',
      'district': '',
      'team': '',
    },
    'zm.north@keralainstitute.org': {
      'name': 'Raghesh Pillai',
      'role': 'ZM',
      'zone': 'North Zone',
      'district': '',
      'team': '',
    },
    'asm.ernakulam@keralainstitute.org': {
      'name': 'Anjali Krishna',
      'role': 'ASM',
      'zone': 'Central Zone',
      'district': 'Ernakulam',
      'team': '',
    },
    'asm.trivandrum@keralainstitute.org': {
      'name': 'Bipin Joseph',
      'role': 'ASM',
      'zone': 'South Zone',
      'district': 'Thiruvananthapuram',
      'team': '',
    },
    'asm.kozhikode@keralainstitute.org': {
      'name': 'Manoj Kumar',
      'role': 'ASM',
      'zone': 'North Zone',
      'district': 'Kozhikode',
      'team': '',
    },
    'bdm.ernakulam.a@keralainstitute.org': {
      'name': 'Deepak S.',
      'role': 'BDM',
      'zone': 'Central Zone',
      'district': 'Ernakulam',
      'team': 'Ernakulam Team A',
    },
    'bdm.ernakulam.b@keralainstitute.org': {
      'name': 'Greeshma P.',
      'role': 'BDM',
      'zone': 'Central Zone',
      'district': 'Ernakulam',
      'team': 'Ernakulam Team B',
    },
    'bdm.trivandrum.a@keralainstitute.org': {
      'name': 'Sanjay R.',
      'role': 'BDM',
      'zone': 'South Zone',
      'district': 'Thiruvananthapuram',
      'team': 'Trivandrum Team A',
    },
    'bdm.kozhikode.a@keralainstitute.org': {
      'name': 'Gautham V.',
      'role': 'BDM',
      'zone': 'North Zone',
      'district': 'Kozhikode',
      'team': 'Kozhikode Team A',
    },
    'bde.ernakulam.a1@keralainstitute.org': {
      'name': 'Rahul R. V.',
      'role': 'BDE',
      'zone': 'Central Zone',
      'district': 'Ernakulam',
      'team': 'Ernakulam Team A',
    },
    'bde.ernakulam.a2@keralainstitute.org': {
      'name': 'Meera K. S.',
      'role': 'BDE',
      'zone': 'Central Zone',
      'district': 'Ernakulam',
      'team': 'Ernakulam Team A',
    },
    'bde.ernakulam.b1@keralainstitute.org': {
      'name': 'Sujith P. V.',
      'role': 'BDE',
      'zone': 'Central Zone',
      'district': 'Ernakulam',
      'team': 'Ernakulam Team B',
    },
    'bde.trivandrum.a1@keralainstitute.org': {
      'name': 'Akhila Mohan',
      'role': 'BDE',
      'zone': 'South Zone',
      'district': 'Thiruvananthapuram',
      'team': 'Trivandrum Team A',
    },
    'bde.trivandrum.a2@keralainstitute.org': {
      'name': 'Siddharth Nair',
      'role': 'BDE',
      'zone': 'South Zone',
      'district': 'Thiruvananthapuram',
      'team': 'Trivandrum Team A',
    },
    'bde.kozhikode.a1@keralainstitute.org': {
      'name': 'Vipin Das',
      'role': 'BDE',
      'zone': 'North Zone',
      'district': 'Kozhikode',
      'team': 'Kozhikode Team A',
    },
    'bde.kozhikode.a2@keralainstitute.org': {
      'name': 'Divya Mukundan',
      'role': 'BDE',
      'zone': 'North Zone',
      'district': 'Kozhikode',
      'team': 'Kozhikode Team A',
    },
    'asm.thrissur@keralainstitute.org': {
      'name': 'Ramesh P.',
      'role': 'ASM',
      'zone': 'Central Zone',
      'district': 'Thrissur',
      'team': '',
    },
    'asm.kollam@keralainstitute.org': {
      'name': 'Deepa S.',
      'role': 'ASM',
      'zone': 'South Zone',
      'district': 'Kollam',
      'team': '',
    },
    'asm.kannur@keralainstitute.org': {
      'name': 'Shine J.',
      'role': 'ASM',
      'zone': 'North Zone',
      'district': 'Kannur',
      'team': '',
    },
    'bdm.thrissur.a@keralainstitute.org': {
      'name': 'Ramesh P. (Sim.)',
      'role': 'BDM',
      'zone': 'Central Zone',
      'district': 'Thrissur',
      'team': 'Thrissur Team A',
    },
    'bde.thrissur.a1@keralainstitute.org': {
      'name': 'Jinto Jose',
      'role': 'BDE',
      'zone': 'Central Zone',
      'district': 'Thrissur',
      'team': 'Thrissur Team A',
    },
    'bdm.kollam.a@keralainstitute.org': {
      'name': 'Deepa S. (Sim.)',
      'role': 'BDM',
      'zone': 'South Zone',
      'district': 'Kollam',
      'team': 'Kollam Team A',
    },
    'bde.kollam.a1@keralainstitute.org': {
      'name': 'Arun Kumar',
      'role': 'BDE',
      'zone': 'South Zone',
      'district': 'Kollam',
      'team': 'Kollam Team A',
    },
    'bdm.kannur.a@keralainstitute.org': {
      'name': 'Shine J. (Sim.)',
      'role': 'BDM',
      'zone': 'North Zone',
      'district': 'Kannur',
      'team': 'Kannur Team A',
    },
    'bde.kannur.a1@keralainstitute.org': {
      'name': 'Suresh Babu',
      'role': 'BDE',
      'zone': 'North Zone',
      'district': 'Kannur',
      'team': 'Kannur Team A',
    },
  };

  /// Check if the user is already logged in (Auto-Login check)
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    return isLoggedIn && rememberMe;
  }

  /// Get details of the active session
  Future<Map<String, String>> getSessionDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyUserEmail) ?? '',
      'authType': prefs.getString(_keyAuthType) ?? 'Unknown',
      'deviceToken': prefs.getString(_keyDeviceToken) ?? 'N/A',
      'name': prefs.getString(_keyUserName) ?? 'Guest User',
      'role': prefs.getString(_keyUserRole) ?? 'BDE',
      'zone': prefs.getString(_keyUserZone) ?? '',
      'district': prefs.getString(_keyUserDistrict) ?? '',
      'team': prefs.getString(_keyUserTeam) ?? '',
    };
  }

  /// Helper to save user profile in preferences
  Future<void> _saveUserProfile(SharedPreferences prefs, String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final profile =
        mockUsers[cleanEmail] ??
        {
          'name': email.split('@').first.toUpperCase(),
          'role': 'BDE',
          'zone': 'Central Zone',
          'district': 'Ernakulam',
          'team': 'Ernakulam Team A',
        };

    await prefs.setString(_keyUserEmail, cleanEmail);
    await prefs.setString(_keyUserName, profile['name'] ?? 'User');
    await prefs.setString(_keyUserRole, profile['role'] ?? 'BDE');
    await prefs.setString(_keyUserZone, profile['zone'] ?? '');
    await prefs.setString(_keyUserDistrict, profile['district'] ?? '');
    await prefs.setString(_keyUserTeam, profile['team'] ?? '');
  }

  /// Authenticate using Email and Password
  Future<bool> loginWithEmail(
    String email,
    String password,
    bool rememberMe,
  ) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.login,
        data: {'employee_id': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          final String token = data['token'] as String;
          final Map<String, dynamic> user =
              data['user'] as Map<String, dynamic>;

          // Save the token to SecureStorageService
          await SecureStorageService.instance.saveAccessToken(token);

          // Extract require_password_change key
          final bool requirePasswordChange =
              body['require_password_change'] == true ||
              data['require_password_change'] == true ||
              user['require_password_change'] == true;

          // Get SharedPreferences instance
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyIsLoggedIn, true);
          await prefs.setString(_keyAuthType, 'Email & Password');
          await prefs.setBool(_keyRememberMe, rememberMe);
          await prefs.setBool(_keyRequirePasswordChange, requirePasswordChange);

          // Extract user details
          final String name = user['name'] ?? 'User';
          final String userEmail = user['email'] ?? email;
          final String designation = user['designation_name'] ?? 'BDE';

          // Map designation to user role code: 'MD' | 'ZM' | 'ASM' | 'BDM' | 'BDE'
          String role = 'BDE';
          final cleanDes = designation.toLowerCase();
          if (cleanDes.contains('managing director') ||
              cleanDes.contains('super admin') ||
              cleanDes.contains('admin')) {
            role = 'MD';
          } else if (cleanDes.contains('zonal')) {
            role = 'ZM';
          } else if (cleanDes.contains('area sales') ||
              cleanDes.contains('district')) {
            role = 'ASM';
          } else if (cleanDes.contains('business development manager') ||
              cleanDes.contains('team leader')) {
            role = 'BDM';
          } else {
            role = 'BDE';
          }

          // Use mapped zone/district/team from mock users if they exist to keep compatibility
          final cleanEmail = userEmail.trim().toLowerCase();
          final mockProfile = mockUsers[cleanEmail];
          final String zone = mockProfile?['zone'] ?? '';
          final String district = mockProfile?['district'] ?? '';
          final String team = mockProfile?['team'] ?? '';

          await prefs.setString(_keyUserEmail, userEmail);
          await prefs.setString(_keyUserName, name);
          await prefs.setString(_keyUserRole, role);
          await prefs.setString(_keyUserZone, zone);
          await prefs.setString(_keyUserDistrict, district);
          await prefs.setString(_keyUserTeam, team);
          await prefs.setString(_keyDeviceToken, token);

          // Save UserSession to SecureStorage too
          await SecureStorageService.instance.saveUserSession(
            UserSession(
              email: userEmail,
              authType: 'Email & Password',
              deviceToken: token,
              name: name,
              role: role,
              zone: zone.isNotEmpty ? zone : null,
              district: district.isNotEmpty ? district : null,
              team: team.isNotEmpty ? team : null,
            ),
          );

          return true;
        }
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('================= LOGIN FAILED =================');
      debugPrint('Error Details: $e');
      if (e is ApiException) {
        debugPrint('Status Code: ${e.statusCode}');
        debugPrint('Message: ${e.message}');
        if (e.details != null) {
          debugPrint('Details: ${e.details}');
        }
      }
      debugPrint('================================================');
    }
    return false;
  }

  /// Trigger Biometric/Device Authentication
  Future<bool> authenticateWithDevice() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canAuthenticateWithBiometrics || isDeviceSupported) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason:
              'Please authenticate to access Kerala Institute Sales App',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (didAuthenticate) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyIsLoggedIn, true);
          await prefs.setString(
            _keyAuthType,
            'Device Authentication (Biometrics)',
          );
          await prefs.setBool(_keyRememberMe, true);
          await _saveUserProfile(
            prefs,
            'bde.ernakulam.a1@keralainstitute.org',
          ); // Default biometric user
          await prefs.setString(
            _keyDeviceToken,
            'biometric_session_${DateTime.now().millisecondsSinceEpoch}',
          );
          return true;
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(
          _keyAuthType,
          'Device Authentication (Simulated Hardware ID)',
        );
        await prefs.setBool(_keyRememberMe, true);
        await _saveUserProfile(prefs, 'bde.ernakulam.a1@keralainstitute.org');
        await prefs.setString(
          _keyDeviceToken,
          'sim_device_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        return true;
      }
    } catch (e) {
      await Future.delayed(const Duration(seconds: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(
        _keyAuthType,
        'Device Authentication (Fallback Token)',
      );
      await prefs.setBool(_keyRememberMe, true);
      await _saveUserProfile(prefs, 'bde.ernakulam.a1@keralainstitute.org');
      await prefs.setString(
        _keyDeviceToken,
        'fallback_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      return true;
    }
    return false;
  }

  /// Simulate a Forgot Password service call
  Future<bool> requestPasswordReset(String email) async {
    if (email.contains('@')) {
      await Future.delayed(const Duration(milliseconds: 1500));
      return true;
    }
    return false;
  }

  /// Logout and clear user session
  Future<bool> logout() async {
    try {
      final session = await getSessionDetails();
      final email = session['email'] ?? '';

      // Skip API logout call for mock demo accounts
      if (!mockUsers.containsKey(email.trim().toLowerCase()) && email.isNotEmpty) {
        await ApiClient.instance.post(ApiEndpoints.logout);
      }
    } catch (e) {
      debugPrint('Logout API failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all SharedPreferences settings, flags and logs
    await SecureStorageService.instance.clearAllData(); // Clear all SecureStorage credentials
    return true;
  }

  /// Check if the current user session has a pending password change requirement
  Future<bool> hasPendingPasswordChange() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRequirePasswordChange) ?? false;
  }

  /// Set/Change password for the logged in user
  Future<bool> changePassword(String newPassword) async {
    try {
      final session = await getSessionDetails();
      final email = session['email'] ?? '';

      // Fallback/Mock bypass for demo accounts to ease development
      if (mockUsers.containsKey(email.trim().toLowerCase()) || email.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 1000));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyRequirePasswordChange, false);
        return true;
      }

      final response = await ApiClient.instance.post(
        ApiEndpoints.changePassword,
        data: {
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyRequirePasswordChange, false);
          return true;
        }
      }
    } catch (e) {
      debugPrint('================= CHANGE PASSWORD FAILED =================');
      debugPrint('Error Details: $e');
      if (e is ApiException) {
        debugPrint('Status Code: ${e.statusCode}');
        debugPrint('Message: ${e.message}');
      }
      debugPrint('===========================================================');
    }
    return false;
  }
}
