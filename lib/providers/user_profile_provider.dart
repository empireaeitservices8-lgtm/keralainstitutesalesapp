import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../models/user_profile_model.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../storage/secure_storage_service.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';

class UserProfileProvider extends BaseProvider<UserProfileModel> {
  static final UserProfileProvider instance = UserProfileProvider._internal();
  UserProfileProvider._internal();

  /// Fetches the user profile details from the GET endpoint `/user/profile`.
  /// Uses cached data as fallback if offline or connection fails.
  Future<void> fetchUserProfile({bool isRefresh = false}) async {
    // If already fetching, ignore duplicate call to avoid spamming the server
    if (state.isLoading) {
      return;
    }

    // If already loaded in memory and not a manual refresh, do not fetch again
    if (!isRefresh && state.data != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // 1. Attempt to load from cache immediately to prevent loading spinner
    final cachedJson = prefs.getString('cached_user_profile');
    UserProfileModel? cachedModel;
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        cachedModel = UserProfileModel.fromJson(decoded);
        if (state.data == null) {
          setState(ApiResponse.success(cachedModel));
        }
      } catch (_) {}
    }

    // Show loading indicator only if we have no cached/loaded data to display
    if (state.data == null) {
      setState(ApiResponse.loading());
    }

    final token = getNewCancelToken();

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.userProfile,
        cancelToken: token,
      );
      if (response.data != null) {
        final rawData = response.data['data'];
        if (rawData == null) {
          throw Exception('User profile data is empty on the server.');
        }

        final Map<String, dynamic> dataMap;
        if (rawData is Map<String, dynamic>) {
          if (rawData.containsKey('user') && rawData['user'] is Map<String, dynamic>) {
            dataMap = rawData['user'] as Map<String, dynamic>;
          } else {
            dataMap = rawData;
          }
        } else {
          throw Exception('Invalid user profile data format.');
        }

        final model = UserProfileModel.fromJson(dataMap);


        // Save fresh data to local cache
        await prefs.setString('cached_user_profile', jsonEncode(model.toJson()));

        setState(ApiResponse.success(model));
        return;
      }
      throw Exception('Failed to fetch user profile data: empty response');
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;

      // 2. Fall back to cached data if network fails so user is not blocked
      if (cachedModel != null) {
        setState(ApiResponse.success(cachedModel));
        return;
      }

      // 3. Format error message
      String errorMsg = e.toString();
      if (errorMsg.contains('ApiException:')) {
        errorMsg = errorMsg.replaceAll('ApiException:', '').trim();
      }
      if (errorMsg.contains('HttpException:') || 
          errorMsg.contains('SocketException:') || 
          errorMsg.contains('DioException') ||
          errorMsg.contains('BAD_DECRYPT')) {
        errorMsg = 'Unable to connect to the server. Please check your internet connection and try again.';
      }

      setState(ApiResponse.error(errorMsg));
    }
  }
}
