import 'auth_service.dart';

class LoginApiService {
  Future<bool> login(String email, String password, bool rememberMe) async {
    return AuthService.instance.loginWithEmail(email, password, rememberMe);
  }

  Future<bool> loginBiometric() async {
    return AuthService.instance.authenticateWithDevice();
  }
}
