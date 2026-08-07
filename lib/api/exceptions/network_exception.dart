import 'api_exception.dart';

class NetworkException extends ApiException {
  NetworkException({
    required super.message,
    super.statusCode,
  });

  @override
  String toString() => 'NetworkException: $message';
}
