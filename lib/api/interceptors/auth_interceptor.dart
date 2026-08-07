import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';
import '../api_endpoints.dart';
import '../../providers/auth_provider.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;

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
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Intercept 401 or 403 authorization failures, skipping auth endpoints to prevent loops
    if ((err.response?.statusCode == 401 || err.response?.statusCode == 403) &&
        err.requestOptions.path != ApiEndpoints.login &&
        err.requestOptions.path != ApiEndpoints.refreshToken) {
      
      final bool isRefreshed = await _attemptTokenRefresh();
      
      if (isRefreshed) {
        try {
          final newAccessToken = await SecureStorageService.instance.getAccessToken();
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
        // Refresh token failed or is invalid, perform automatic logout
        await _performForceLogout();
      }
    }

    return handler.next(err);
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
  Future<void> _performForceLogout() async {
    await SecureStorageService.instance.clearAuthData();
    // Safely update AuthProvider to log user out visually
    try {
      await AuthProvider.instance.logout();
    } catch (_) {}
  }
}
