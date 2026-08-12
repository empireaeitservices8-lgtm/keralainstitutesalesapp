import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    // Evaluate whether the exception is eligible for retry
    if (_shouldRetry(err)) {
      final int retryCount = options.extra['retry_count'] ?? 0;

      if (retryCount < maxRetries) {
        final int nextRetryCount = retryCount + 1;
        options.extra['retry_count'] = nextRetryCount;

        // Exponential backoff delay calculation: initialDelay * 2^(nextRetryCount - 1)
        final int multiplier = 1 << (nextRetryCount - 1); // Equivalent to 2^(nextRetryCount - 1)
        final Duration backoffDelay = initialDelay * multiplier;

        // Delay execution
        await Future.delayed(backoffDelay);

        try {
          // Re-fetch original request configuration
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          // If the retry attempt throws a DioException, propagate it; otherwise, propagate original error
          if (e is DioException) {
            return handler.next(e);
          }
          return handler.next(err);
        }
      }
    }

    return handler.next(err);
  }

  /// Determines if the query should be retried based on exception type and response code.
  bool _shouldRetry(DioException err) {
    // Never retry FormData requests because they cannot be read multiple times once finalized
    if (err.requestOptions.data is FormData) {
      return false;
    }

    // SSL Decryption or Handshake failures (which map to DioExceptionType.unknown or connectionError)
    // These occur at the socket layer before the request is received by the server, so it's safe to retry for any method.
    final errorString = err.toString().toLowerCase() + (err.error?.toString().toLowerCase() ?? '');
    final isTlsFailure = errorString.contains('decrypt') ||
        errorString.contains('handshake') ||
        errorString.contains('tls_record') ||
        errorString.contains('bad_record_mac');

    if (isTlsFailure) {
      return true;
    }

    // Only retry GET requests (idempotent read operations) for other connection errors to avoid duplicate form submissions
    if (err.requestOptions.method.toUpperCase() != 'GET') {
      return false;
    }

    // Timeout issues
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // Connection errors (SocketException or no route to host)
    if (err.type == DioExceptionType.connectionError) {
      return true;
    }

    // 5xx Server failures
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
        return true;
      }
    }

    return false;
  }
}
