import 'api_exception.dart';

class UnauthorizedException extends ApiException {
  UnauthorizedException({
    required super.message,
    super.statusCode = 401,
  });

  @override
  String toString() => 'UnauthorizedException: $message';
}
