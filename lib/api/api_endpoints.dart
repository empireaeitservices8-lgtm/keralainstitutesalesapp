class ApiEndpoints {
  ApiEndpoints._();

  /// Change the base URL to target staging/production/local servers
  static const String baseUrl =
      'https://kide-crm-backend-production-yszlaa.laravel.cloud/api';

  /// Authentication
  static const String login = '/login';
  static const String logout = '/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String changePassword = '/set-password';

  /// Features (Placeholder endpoint maps, can be adapted/configured)
  static const String userProfile = '/profile';
  static const String attendance = '/attendance';
  static const String operations = '/operations';
  static const String home = '/home';
  static const String walletBalance = '/wallet/balance';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String leaves = '/leaves';
  static const String applyLeave = '/leaves/apply';
  static const String designations = '/designations';
  static const String register = '/register';
}
