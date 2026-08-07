import 'package:dio/dio.dart';
import '../api/exceptions/api_exception.dart';

abstract class BaseRepository {
  /// Safely executes an API call that returns a single object.
  /// Maps raw JSON response data using the provided `mapper` closure.
  Future<T> safeApiCall<T>({
    required Future<Response<dynamic>> Function() call,
    required T Function(dynamic json) mapper,
  }) async {
    try {
      final response = await call();
      final data = response.data;
      if (data == null) {
        throw ApiException(
          message: 'The server returned an empty response body.',
          statusCode: response.statusCode,
        );
      }
      return mapper(data);
    } catch (e) {
      // Reraise ApiException, NetworkException, or UnauthorizedException thrown by ApiClient
      rethrow;
    }
  }

  /// Safely executes an API call that returns a list of objects.
  Future<List<T>> safeApiCallList<T>({
    required Future<Response<dynamic>> Function() call,
    required T Function(dynamic json) mapper,
  }) async {
    try {
      final response = await call();
      final data = response.data;
      if (data == null) {
        return [];
      }
      if (data is List) {
        return data.map((item) => mapper(item)).toList();
      } else if (data is Map && data.containsKey('data') && data['data'] is List) {
        // Handle common envelope structures where the list resides inside a 'data' key
        return (data['data'] as List).map((item) => mapper(item)).toList();
      }
      
      throw ApiException(
        message: 'Expected a list structure but received: ${data.runtimeType}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      rethrow;
    }
  }
}
