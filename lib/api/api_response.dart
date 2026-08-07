enum ApiStatus { loading, success, error, empty }

class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.status,
    this.data,
    this.message,
    this.statusCode,
  });

  /// Factory helper for Loading state
  factory ApiResponse.loading({String? message}) => ApiResponse(
        status: ApiStatus.loading,
        message: message,
      );

  /// Factory helper for Success state
  factory ApiResponse.success(T data, {int? statusCode, String? message}) => ApiResponse(
        status: ApiStatus.success,
        data: data,
        statusCode: statusCode,
        message: message,
      );

  /// Factory helper for Error state
  factory ApiResponse.error(String message, {int? statusCode}) => ApiResponse(
        status: ApiStatus.error,
        message: message,
        statusCode: statusCode,
      );

  /// Factory helper for Empty state (e.g. 204 or empty list)
  factory ApiResponse.empty({String? message, int? statusCode}) => ApiResponse(
        status: ApiStatus.empty,
        message: message,
        statusCode: statusCode,
      );

  bool get isLoading => status == ApiStatus.loading;
  bool get isSuccess => status == ApiStatus.success;
  bool get isError => status == ApiStatus.error;
  bool get isEmpty => status == ApiStatus.empty;

  @override
  String toString() =>
      'ApiResponse(status: $status, statusCode: $statusCode, message: $message, data: $data)';
}
