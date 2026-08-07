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
