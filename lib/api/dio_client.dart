import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
          'Connection': 'close',
        },
        responseType: ResponseType.json,
      ),
    );

    // Disable connection keep-alive pooling to bypass BAD_DECRYPT keep-alive bugs
    // and override bad certificate validation to prevent handshake failures on proxy/VPN connections
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.idleTimeout = Duration.zero;
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    // Interceptors pipeline
    dio.interceptors.addAll([
      AuthInterceptor(dio),
      RetryInterceptor(dio),
      ApiLoggingInterceptor(),
    ]);
  }
}
