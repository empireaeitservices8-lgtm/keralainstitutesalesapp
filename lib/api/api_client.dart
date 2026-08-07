import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/network_checker.dart';
import 'dio_client.dart';
import 'exceptions/api_exception.dart';
import 'exceptions/network_exception.dart';
import 'exceptions/unauthorized_exception.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  final Dio _dio = DioClient.instance.dio;

  /// Helper to enforce network connection before making any request
  Future<void> _verifyConnectivity() async {
    final hasInternet = await NetworkChecker.instance.hasConnection();
    if (!hasInternet) {
      throw NetworkException(message: 'No Internet Connection');
    }
  }

  /// Generic GET request wrapper
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _verifyConnectivity();
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _processDioError(e);
    }
  }

  /// Generic POST request wrapper
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _verifyConnectivity();
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _processDioError(e);
    }
  }

  /// Generic PUT request wrapper
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _verifyConnectivity();
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _processDioError(e);
    }
  }

  /// Generic PATCH request wrapper
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _verifyConnectivity();
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _processDioError(e);
    }
  }

  /// Generic DELETE request wrapper
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _verifyConnectivity();
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _processDioError(e);
    }
  }

  /// Multipart File Upload wrapper
  Future<Response<T>> uploadMultipart<T>(
    String path, {
    required Map<String, dynamic> data,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    await _verifyConnectivity();
    try {
      final formData = FormData.fromMap(data);
      return await _dio.post<T>(
        path,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _processDioError(e);
    }
  }

  /// File Download wrapper
  Future<Response> downloadFile(
    String urlPath,
    dynamic savePath, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _verifyConnectivity();
    try {
      return await _dio.download(
        urlPath,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _processDioError(e);
    }
  }

  /// Standardizes DioExceptions into user-friendly ApiException classes
  Exception _processDioError(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return ApiException(message: 'Request was cancelled', statusCode: 499);
    }

    // Intercept SSL/TLS Handshake and Bad Decrypt errors
    if (error.error is HandshakeException ||
        error.message?.contains('HandshakeException') == true ||
        error.message?.contains('BAD_DECRYPT') == true ||
        error.message?.contains('DECRYPTION_FAILED') == true) {
      return NetworkException(
        message: 'Secure connection handshake failed. Please disable your VPN, check your network connection, or try switching to cellular data.',
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        message: 'Connection timed out. Please check your network and try again.',
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return NetworkException(
        message: 'No internet connection or server is unreachable.',
      );
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      final responseData = response.data;
      
      // Attempt to pull message from API JSON error format
      String errorMessage = 'A server error occurred. Please try again.';
      if (responseData is Map) {
        errorMessage = responseData['message'] ?? responseData['error'] ?? errorMessage;
      } else if (response.statusMessage != null && response.statusMessage!.isNotEmpty) {
        errorMessage = response.statusMessage!;
      }

      if (statusCode == 401 || statusCode == 403) {
        return UnauthorizedException(
          message: errorMessage,
          statusCode: statusCode,
        );
      }

      // Map common client error responses
      switch (statusCode) {
        case 400:
          return ApiException(message: 'Bad Request: $errorMessage', statusCode: 400, details: responseData);
        case 404:
          return ApiException(message: 'Not Found: $errorMessage', statusCode: 404, details: responseData);
        case 409:
          return ApiException(message: 'Conflict: $errorMessage', statusCode: 409, details: responseData);
        case 422:
          return ApiException(message: 'Validation Error: $errorMessage', statusCode: 422, details: responseData);
        case 429:
          return ApiException(message: 'Too Many Requests: Please slow down.', statusCode: 429, details: responseData);
        case 500:
          return ApiException(message: 'Internal Server Error. Please contact support.', statusCode: 500, details: responseData);
        case 502:
          return ApiException(message: 'Bad Gateway: Server is temporarily unavailable.', statusCode: 502, details: responseData);
        case 503:
          return ApiException(message: 'Service Unavailable. Under maintenance.', statusCode: 503, details: responseData);
        case 504:
          return ApiException(message: 'Gateway Timeout: Connection expired.', statusCode: 504, details: responseData);
        default:
          return ApiException(message: errorMessage, statusCode: statusCode, details: responseData);
      }
    }

    return ApiException(
      message: error.message ?? 'An unexpected network error occurred.',
    );
  }
}
