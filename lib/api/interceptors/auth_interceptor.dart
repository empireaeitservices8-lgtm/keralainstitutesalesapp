import 'package:dio/dio.dart';
import '../../services/common/navigation_services.dart';
import '../../storage/secure_storage_service.dart';
import '../api_endpoints.dart';
import '../../providers/auth_provider.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  static bool _isNavigatingToLogin = false;

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip injecting token for authentication endpoints (login, refresh token)
    if (options.path == ApiEndpoints.login ||
        options.path == ApiEndpoints.refreshToken) {
      return handler.next(options);
    }

    final accessToken = await SecureStorageService.instance.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final path = response.requestOptions.path;

    // Check if the response body indicates unauthenticated even with a 200/2xx status
    if (!_isAuthEndpoint(path) &&
        _isUnauthenticated(response.statusCode, response.data)) {
      await _performForceLogout();
    }

    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    final isAuth = _isAuthEndpoint(path);

    // Intercept unauthenticated / 401 / 403 authorization failures, skipping auth endpoints to prevent loops
    if (!isAuth && _isUnauthenticated(statusCode, err.response?.data)) {
      final bool isRefreshed = await _attemptTokenRefresh();

      if (isRefreshed) {
        try {
          final newAccessToken =
              await SecureStorageService.instance.getAccessToken();
          final options = err.requestOptions;

          if (newAccessToken != null) {
            options.headers['Authorization'] = 'Bearer $newAccessToken';
          }

          // Re-dispatch original request with new token
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          // If the retried request fails, forward the error
          return handler.next(err);
        }
      } else {
        // Refresh token failed or is invalid, perform automatic logout and navigate to login
        await _performForceLogout();
      }
    }

    return handler.next(err);
  }

  bool _isAuthEndpoint(String path) {
    final cleanPath = Uri.tryParse(path)?.path ?? path;
    final normalized = cleanPath.replaceAll(RegExp(r'/+$'), '');
    return normalized.endsWith(ApiEndpoints.login) ||
        normalized.endsWith(ApiEndpoints.refreshToken) ||
        normalized.endsWith(ApiEndpoints.logout);
  }

  bool _isUnauthenticated(int? statusCode, dynamic data) {
    if (statusCode == 401 || statusCode == 403) {
      return true;
    }
    if (data != null) {
      if (data is Map) {
        final message =
            (data['message'] ?? data['error'] ?? data['msg'] ?? '')
                .toString()
                .toLowerCase();
        if (message.contains('unauthenticated') ||
            message.contains('unauthorized') ||
            message.contains('token expired') ||
            message.contains('token has expired') ||
            message.contains('token invalid') ||
            message.contains('jwt expired')) {
          return true;
        }
      } else if (data is String) {
        final lower = data.toLowerCase();
        if (lower.contains('unauthenticated') ||
            lower.contains('token expired') ||
            lower.contains('jwt expired')) {
          return true;
        }
      }
    }
    return false;
  }

  /// Attempts to perform a refresh token operation.
  Future<bool> _attemptTokenRefresh() async {
    final refreshToken = await SecureStorageService.instance.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      // Create a clean Dio instance specifically for refresh to avoid loops/interceptors
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> responseData = response.data;
        // Adjust these keys based on the API response structure
        final newAccessToken = responseData['accessToken'] as String?;
        final newRefreshToken = responseData['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await SecureStorageService.instance.saveAccessToken(newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await SecureStorageService.instance.saveRefreshToken(newRefreshToken);
          }
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Handles forced logout of the user, resetting local authentication states
  /// and navigating to the Login screen.
  Future<void> _performForceLogout() async {
    if (_isNavigatingToLogin) return;
    _isNavigatingToLogin = true;

    try {
      // 1. Immediately trigger navigation to login screen
      navigateToLogin();

      // 2. Clear credentials in secure storage
      await SecureStorageService.instance.clearAuthData();

      // 3. Clear auth session in AuthProvider and SharedPreferences WITHOUT calling API logout
      try {
        await AuthProvider.instance.logout(callApi: false);
      } catch (_) {}
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _isNavigatingToLogin = false;
      });
    }
  }
}
