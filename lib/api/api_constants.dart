class ApiConstants {
  ApiConstants._();

  /// Connection, Receive, and Send Timeouts in Milliseconds
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Headers
  static const String acceptHeader = 'application/json';
  static const String contentTypeHeader = 'application/json';
}
