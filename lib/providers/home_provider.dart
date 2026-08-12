import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../models/home_dashboard_model.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../storage/secure_storage_service.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';
import 'operations_provider.dart';
import 'wallet_provider.dart';
import 'user_profile_provider.dart';

class HomeProvider extends BaseProvider<HomeDashboardModel> {
  static final HomeProvider instance = HomeProvider._internal();
  HomeProvider._internal();

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _gpsLoggingEnforced = true;
  bool _biometricEnforced = true;
  bool _autoSyncActive = true;

  bool get gpsLoggingEnforced => _gpsLoggingEnforced;
  bool get biometricEnforced => _biometricEnforced;
  bool get autoSyncActive => _autoSyncActive;
  int? _selectedDistrictId;
  int? get selectedDistrictId => _selectedDistrictId;

  void setSelectedDistrictId(int? id) {
    _selectedDistrictId = id;
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
    _triggerTabApiCalls(index);
  }

  void _triggerTabApiCalls(int index) {
    switch (index) {
      case 0:
        final user = AuthProvider.instance.session;
        if (user.role == 'ZM') {
          OperationsProvider.instance.fetchDistricts();
        }
        fetchHomeData();
        break;
      case 1:
        // Centralized fetch for leads tab (includes hierarchy filters and raw tasks)
        OperationsProvider.instance.fetchLeads(status: 1);
        OperationsProvider.instance.fetchHierarchyFilters();
        break;
      case 2:
        // Centralized fetch for incentive tab
        WalletProvider.instance.fetchWalletBalance();
        break;
      case 3:
        // Centralized fetch for profile tab
        UserProfileProvider.instance.fetchUserProfile();
        break;
    }
  }

  void setGpsLoggingEnforced(bool val) {
    _gpsLoggingEnforced = val;
    notifyListeners();
  }

  void setBiometricEnforced(bool val) {
    _biometricEnforced = val;
    notifyListeners();
  }

  void setAutoSyncActive(bool val) {
    _autoSyncActive = val;
    notifyListeners();
  }

  Future<void> fetchHomeData({bool isRefresh = false, int? districtId}) async {
    // If already fetching, ignore duplicate call
    if (state.isLoading) {
      return;
    }
    // If already loaded in memory and not a manual refresh, do not fetch again
    if (!isRefresh && state.data != null) {
      return;
    }

    final user = AuthProvider.instance.session;
    if (user.role == 'ZM' && (isRefresh || OperationsProvider.instance.districts.isEmpty)) {
      OperationsProvider.instance.fetchDistricts();
    }

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

    final activeDistrictId = districtId ?? _selectedDistrictId;
    final Map<String, dynamic> queryParams = {};
    if (activeDistrictId != null) {
      queryParams['district_id'] = activeDistrictId;
    }

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.home,
        queryParameters: queryParams,
        cancelToken: token,
      );
      if (response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final model = HomeDashboardModel.fromJson(data);

        // Dynamically verify and update active user role from home dashboard data designation
        final String updatedRole = AuthService.mapDesignationIdToRole(model.designationId, model.designationName);
        final currentRole = AuthProvider.instance.session.role;
        if (updatedRole != currentRole) {
          AuthProvider.instance.updateSessionRole(updatedRole);
          await prefs.setString('user_role', updatedRole);
          final session = AuthProvider.instance.session;
          await SecureStorageService.instance.saveUserSession(session);
        }

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
