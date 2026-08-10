import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'api_endpoints.dart';
import 'interceptors/api_logging_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class DioClient {
  static final DioClient instance = DioClient._internal();
  late final Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        persistentConnection: false,
        headers: {
          'Accept': ApiConstants.acceptHeader,
          'Content-Type': ApiConstants.contentTypeHeader,
          'Connection': 'close', // Force clean TLS handshake each request, avoiding keep-alive decryption bugs
        },
        responseType: ResponseType.json,
      ),
    );

    // Interceptors pipeline
    dio.interceptors.addAll([
      AuthInterceptor(dio),
      RetryInterceptor(dio),
      ApiLoggingInterceptor(),
    ]);
  }
}
