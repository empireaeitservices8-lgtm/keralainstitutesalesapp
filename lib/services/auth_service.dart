import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final profile = mockUsers[cleanEmail] ?? {
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
  Future<bool> loginWithEmail(String email, String password, bool rememberMe) async {
    // For demo/sales app purposes, we allow any valid-looking email with password longer than 5 chars
    if (email.contains('@') && password.length >= 6) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyAuthType, 'Email & Password');
      await prefs.setBool(_keyRememberMe, rememberMe);
      await _saveUserProfile(prefs, email);
      // Generate a mock secure session/device token
      await prefs.setString(_keyDeviceToken, 'email_session_${DateTime.now().millisecondsSinceEpoch}');
      return true;
    }
    return false;
  }

  /// Trigger Biometric/Device Authentication
  Future<bool> authenticateWithDevice() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canAuthenticateWithBiometrics || isDeviceSupported) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access Kerala Institute Sales App',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (didAuthenticate) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyIsLoggedIn, true);
          await prefs.setString(_keyAuthType, 'Device Authentication (Biometrics)');
          await prefs.setBool(_keyRememberMe, true);
          await _saveUserProfile(prefs, 'bde.ernakulam.a1@keralainstitute.org'); // Default biometric user
          await prefs.setString(_keyDeviceToken, 'biometric_session_${DateTime.now().millisecondsSinceEpoch}');
          return true;
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyAuthType, 'Device Authentication (Simulated Hardware ID)');
        await prefs.setBool(_keyRememberMe, true);
        await _saveUserProfile(prefs, 'bde.ernakulam.a1@keralainstitute.org');
        await prefs.setString(_keyDeviceToken, 'sim_device_token_${DateTime.now().millisecondsSinceEpoch}');
        return true;
      }
    } catch (e) {
      await Future.delayed(const Duration(seconds: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyAuthType, 'Device Authentication (Fallback Token)');
      await prefs.setBool(_keyRememberMe, true);
      await _saveUserProfile(prefs, 'bde.ernakulam.a1@keralainstitute.org');
      await prefs.setString(_keyDeviceToken, 'fallback_token_${DateTime.now().millisecondsSinceEpoch}');
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyAuthType);
    await prefs.remove(_keyDeviceToken);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserZone);
    await prefs.remove(_keyUserDistrict);
    await prefs.remove(_keyUserTeam);
    return true;
  }
}
