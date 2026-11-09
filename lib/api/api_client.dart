import 'dart:convert';
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
        options: Options(
          contentType: 'multipart/form-data',
        ),
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
    if (error.type == DioExceptionType.cancel || CancelToken.isCancel(error)) {
      return error;
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
      
      // Attempt to pull exact message from API JSON error format
      String? serverMessage;
      if (responseData is Map) {
        if (responseData['message'] != null &&
            responseData['message'].toString().trim().isNotEmpty) {
          serverMessage = responseData['message'].toString().trim();
        } else if (responseData['error'] != null &&
            responseData['error'].toString().trim().isNotEmpty) {
          serverMessage = responseData['error'].toString().trim();
        } else if (responseData['errors'] is Map) {
          final errorsMap = responseData['errors'] as Map;
          if (errorsMap.isNotEmpty) {
            final firstVal = errorsMap.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              serverMessage = firstVal.first.toString().trim();
            } else if (firstVal != null) {
              serverMessage = firstVal.toString().trim();
            }
          }
        }
      } else if (responseData is String && responseData.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(responseData);
          if (decoded is Map) {
            if (decoded['message'] != null &&
                decoded['message'].toString().trim().isNotEmpty) {
              serverMessage = decoded['message'].toString().trim();
            } else if (decoded['error'] != null &&
                decoded['error'].toString().trim().isNotEmpty) {
              serverMessage = decoded['error'].toString().trim();
            }
          }
        } catch (_) {
          if (!responseData.contains('<!DOCTYPE html>') &&
              responseData.length < 300) {
            serverMessage = responseData.trim();
          }
        }
      }

      // If server sent a specific error message, use it directly across all status codes!
      if (serverMessage != null && serverMessage.isNotEmpty) {
        final lowerMsg = serverMessage.toLowerCase();
        if (statusCode == 401 ||
            statusCode == 403 ||
            lowerMsg.contains('unauthenticated') ||
            lowerMsg.contains('jwt expired') ||
            lowerMsg.contains('token expired')) {
          return UnauthorizedException(
            message: serverMessage,
            statusCode: statusCode ?? 401,
          );
        }
        return ApiException(
          message: serverMessage,
          statusCode: statusCode,
          details: responseData,
        );
      }

      // Default fallback messages when the server provided no custom message
      String fallbackMessage = 'A server error occurred. Please try again.';
      if (response.statusMessage != null && response.statusMessage!.isNotEmpty) {
        fallbackMessage = response.statusMessage!;
      }

      switch (statusCode) {
        case 400:
          return ApiException(message: fallbackMessage.isNotEmpty ? fallbackMessage : 'Bad Request (400)', statusCode: 400, details: responseData);
        case 401:
        case 403:
          return UnauthorizedException(message: 'Authentication failed. Please login again.', statusCode: statusCode ?? 401);
        case 404:
          return ApiException(message: 'Requested resource not found (404)', statusCode: 404, details: responseData);
        case 409:
          return ApiException(message: 'Conflict: Request could not be completed', statusCode: 409, details: responseData);
        case 422:
          return ApiException(message: 'Validation failed. Please verify your input.', statusCode: 422, details: responseData);
        case 429:
          return ApiException(message: 'Too many requests. Please slow down and try again.', statusCode: 429, details: responseData);
        case 500:
          return ApiException(message: 'Internal server error. Please try again later.', statusCode: 500, details: responseData);
        case 502:
          return ApiException(message: 'Server temporarily unavailable (502).', statusCode: 502, details: responseData);
        case 503:
          return ApiException(message: 'Service under maintenance (503).', statusCode: 503, details: responseData);
        case 504:
          return ApiException(message: 'Gateway timeout (504). Please check your connection.', statusCode: 504, details: responseData);
        default:
          return ApiException(message: fallbackMessage, statusCode: statusCode, details: responseData);
      }
    }

    return ApiException(
      message: error.message ?? 'An unexpected network error occurred.',
    );
  }
}
