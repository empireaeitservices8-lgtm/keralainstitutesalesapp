import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../models/home_dashboard_model.dart';
import 'base_provider.dart';

class HomeProvider extends BaseProvider<HomeDashboardModel> {
  static final HomeProvider instance = HomeProvider._internal();
  HomeProvider._internal();

  /// Fetches the home dashboard metrics from the `/home` endpoint.
  /// Uses cached data as fallback if offline or connection fails.
  Future<void> fetchHomeData({bool isRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Attempt to load from cache immediately to prevent loading spinner
    final cachedJson = prefs.getString('cached_home_data');
    HomeDashboardModel? cachedModel;
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        cachedModel = HomeDashboardModel.fromJson(decoded);
        if (state.data == null) {
          setState(ApiResponse.success(cachedModel));
        }
      } catch (_) {}
    }

    // Show loading indicator only if we have no cached data to display
    if (state.data == null) {
      setState(ApiResponse.loading());
    }

    final token = getNewCancelToken();

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.home,
        cancelToken: token,
      );
      if (response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final model = HomeDashboardModel.fromJson(data);

        // Save fresh data to local cache
        await prefs.setString('cached_home_data', jsonEncode(model.toJson()));

        setState(ApiResponse.success(model));
        return;
      }
      throw Exception('Failed to fetch home dashboard data: empty response');
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;

      // 2. Fall back to cached data if network fails so user is not blocked
      if (cachedModel != null) {
        setState(ApiResponse.success(cachedModel));
        return;
      }

      // 3. If no cache exists, format a user-friendly error message
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
