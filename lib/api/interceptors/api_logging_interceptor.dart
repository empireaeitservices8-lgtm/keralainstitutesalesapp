import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;

      debugPrint(' ');
      debugPrint('┌───────────────────────────────────────────────────────────────');
      debugPrint('│ 🚀 API REQUEST: [${options.method}] -> ${options.uri}');
      debugPrint('├───────────────────────────────────────────────────────────────');

      final headers = Map<String, dynamic>.from(options.headers);
      debugPrint('│ Headers: $headers');
      debugPrint('│ Query Parameters: ${options.queryParameters}');

      if (options.data != null) {
        if (options.data is FormData) {
          final formData = options.data as FormData;
          debugPrint('│ Body (FormData):');
          for (var field in formData.fields) {
            debugPrint('│   ${field.key}: ${field.value}');
          }
          for (var file in formData.files) {
            debugPrint('│   File field: ${file.key} (${file.value.filename}, size: ${file.value.length} bytes)');
          }
        } else {
          try {
            final prettyJson = const JsonEncoder.withIndent('  ').convert(options.data);
            final lines = prettyJson.split('\n');
            debugPrint('│ Body (JSON):');
            for (var line in lines) {
              debugPrint('│   $line');
            }
          } catch (_) {
            debugPrint('│ Body: ${options.data}');
          }
        }
      }
      debugPrint('│ Request Time: ${DateTime.now()}');
      debugPrint('└───────────────────────────────────────────────────────────────');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final startTime = response.requestOptions.extra['request_start_time'] as int?;
      final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;

      debugPrint(' ');
      debugPrint('┌───────────────────────────────────────────────────────────────');
      debugPrint('│ ✅ API RESPONSE: [Status: ${response.statusCode}] <- ${response.requestOptions.uri}');
      debugPrint('├───────────────────────────────────────────────────────────────');
      debugPrint('│ Response Headers: ${response.headers.map}');

      if (response.data != null) {
        try {
          final prettyJson = const JsonEncoder.withIndent('  ').convert(response.data);
          final lines = prettyJson.split('\n');
          debugPrint('│ Response JSON:');
          for (var line in lines) {
            debugPrint('│   $line');
          }
        } catch (_) {
          debugPrint('│ Response Data: ${response.data}');
        }
      }
      if (duration != null) {
        debugPrint('│ Total Execution Time: ${duration}ms');
      }
      debugPrint('└───────────────────────────────────────────────────────────────');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final startTime = err.requestOptions.extra['request_start_time'] as int?;
      final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;

      debugPrint(' ');
      debugPrint('┌───────────────────────────────────────────────────────────────');
      debugPrint('│ ❌ API ERROR: [DioException: ${err.type}] <- ${err.requestOptions.uri}');
      debugPrint('├───────────────────────────────────────────────────────────────');
      debugPrint('│ HTTP Status Code: ${err.response?.statusCode}');
      debugPrint('│ Error Message: ${err.message}');
      debugPrint('│ Underlying Error: ${err.error}');

      if (err.response?.data != null) {
        try {
          final prettyJson = const JsonEncoder.withIndent('  ').convert(err.response!.data);
          final lines = prettyJson.split('\n');
          debugPrint('│ Server Error Response JSON:');
          for (var line in lines) {
            debugPrint('│   $line');
          }
        } catch (_) {
          debugPrint('│ Server Error Response Data: ${err.response!.data}');
        }
      }
      if (duration != null) {
        debugPrint('│ Total API Request Time: ${duration}ms');
      }
      if (err.stackTrace != null) {
        debugPrint('│ Stack Trace:');
        final lines = err.stackTrace.toString().split('\n');
        for (var line in lines.take(10)) { // limit printing of stacktrace lines to keep output clean
          debugPrint('│   $line');
        }
      }
      debugPrint('└───────────────────────────────────────────────────────────────');
    }
    super.onError(err, handler);
  }
}
