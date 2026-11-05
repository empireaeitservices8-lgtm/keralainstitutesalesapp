import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../api/exceptions/api_exception.dart';
import '../models/home_dashboard_model.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import 'attendance_provider.dart';
import 'operations_provider.dart';
import 'wallet_provider.dart';
import 'user_profile_provider.dart';
import '../models/performance_task.dart';

class HomeProvider extends BaseProvider<HomeDashboardModel> {
  static final HomeProvider instance = HomeProvider._internal();
  HomeProvider._internal();

  PerformanceTasksSummary? _tasksSummary;
  PerformanceTasksSummary? get tasksSummary => _tasksSummary;

  List<PerformanceTask> _performanceTasks = [];
  List<PerformanceTask> get performanceTasks => _performanceTasks;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _initialTaskTabIndex = 0;
  int get initialTaskTabIndex => _initialTaskTabIndex;

  int? _pendingTaskTabIndex;

  bool _gpsLoggingEnforced = true;
  bool _biometricEnforced = true;
  bool _autoSyncActive = true;

  bool get gpsLoggingEnforced => _gpsLoggingEnforced;
  bool get biometricEnforced => _biometricEnforced;
  bool get autoSyncActive => _autoSyncActive;
  int? _selectedDistrictId;
  int? get selectedDistrictId => _selectedDistrictId;

  HomeAttendance? _statusAttendance;
  HomeAttendance? get statusAttendance => _statusAttendance;

  void updateAttendanceFromStatus({
    required String checkInTime,
    required String checkOutTime,
    required String shiftStatus,
    required bool isCheckedIn,
    required bool isCheckedOut,
    String date = '',
    double hoursWorked = 0.0,
  }) {
    final current = state.data;
    final newAttendance = HomeAttendance(
      checkInTime: (checkInTime.isNotEmpty && checkInTime != 'null')
          ? checkInTime
          : (current?.attendance?.checkInTime ?? ''),
      checkOutTime: (checkOutTime.isNotEmpty && checkOutTime != 'null')
          ? checkOutTime
          : (current?.attendance?.checkOutTime ?? ''),
      shiftStatus: shiftStatus.isNotEmpty
          ? shiftStatus
          : (current?.attendance?.shiftStatus ?? 'OFFLINE'),
      isCheckedIn: isCheckedIn,
      isCheckedOut: isCheckedOut,
      date: date.isNotEmpty ? date : (current?.attendance?.date ?? ''),
      hoursWorked: hoursWorked > 0 ? hoursWorked : (current?.attendance?.hoursWorked ?? 0.0),
    );

    _statusAttendance = newAttendance;

    if (current != null) {
      final updatedModel = current.copyWith(attendance: newAttendance);
      setState(ApiResponse.success(updatedModel));
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('cached_home_data', jsonEncode(updatedModel.toJson()));
      }).catchError((_) {});
    }
  }

  void setSelectedDistrictId(int? id) {
    _selectedDistrictId = id;
    notifyListeners();
  }

  void addPerformanceTask(PerformanceTask task) {
    _performanceTasks.insert(0, task);
    if (_tasksSummary != null) {
      _tasksSummary = PerformanceTasksSummary(
        total: _tasksSummary!.total + 1,
        completed: _tasksSummary!.completed + (task.isCompleted ? 1 : 0),
        pending: _tasksSummary!.pending + (task.isCompleted ? 0 : 1),
        list: _performanceTasks,
      );
    } else {
      _tasksSummary = PerformanceTasksSummary(
        total: 1,
        completed: task.isCompleted ? 1 : 0,
        pending: task.isCompleted ? 0 : 1,
        list: _performanceTasks,
      );
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        'cached_tasks_summary',
        jsonEncode(_tasksSummary!.toJson()),
      );
    }).catchError((_) {});
    notifyListeners();
  }

  void setCurrentIndex(int index, {int? initialTaskTabIndex}) {
    _currentIndex = index;
    if (initialTaskTabIndex != null) {
      _initialTaskTabIndex = initialTaskTabIndex;
      _pendingTaskTabIndex = initialTaskTabIndex;
    } else {
      _initialTaskTabIndex = 0;
    }
    notifyListeners();
    _triggerTabApiCalls(index);
  }

  int consumeInitialTaskTabIndex() {
    final val = _pendingTaskTabIndex ?? _initialTaskTabIndex;
    _pendingTaskTabIndex = null;
    return val;
  }

  int? consumePendingTaskTabIndex() {
    final val = _pendingTaskTabIndex;
    _pendingTaskTabIndex = null;
    return val;
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
        if (_initialTaskTabIndex == 1) {
          OperationsProvider.instance.fetchCompletedLeads();
        } else {
          OperationsProvider.instance.fetchLeads(status: 1);
        }
        final user = AuthProvider.instance.session;
        if (user.role != 'BDE') {
          OperationsProvider.instance.fetchHierarchyFilters();
        }
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

  bool _isFetchingHome = false;

  Future<void> fetchHomeData({bool isRefresh = false, int? districtId}) async {
    // If already fetching, ignore duplicate call
    if (_isFetchingHome || state.isLoading) {
      return;
    }
    // If already loaded in memory and not a manual refresh, do not fetch again
    if (!isRefresh && state.data != null && districtId == null) {
      return;
    }

    _isFetchingHome = true;

    if (isRefresh || OperationsProvider.instance.districts.isEmpty) {
      OperationsProvider.instance.fetchDistricts(isRefresh: isRefresh);
      OperationsProvider.instance.fetchZones(isRefresh: isRefresh);
      OperationsProvider.instance.fetchCourses(isRefresh: isRefresh);
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
        if (cachedModel.attendance != null) {
          AttendanceProvider.instance.syncAttendanceFromHome(
            checkedIn: cachedModel.attendance!.isCheckedIn,
            checkedOut: cachedModel.attendance!.isCheckedOut,
            checkInTimeStr: cachedModel.attendance!.checkInTime,
            checkOutTimeStr: cachedModel.attendance!.checkOutTime,
            status: cachedModel.attendance!.shiftStatus,
          );
        }
      } catch (_) {}
    }

    final cachedTasksStr = prefs.getString('cached_tasks_summary');
    if (cachedTasksStr != null) {
      try {
        final decodedTasks = jsonDecode(cachedTasksStr);
        _tasksSummary = PerformanceTasksSummary.fromJson(decodedTasks);
        _performanceTasks = _tasksSummary!.list;
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
      final results = await Future.wait([
        ApiClient.instance.get(
          ApiEndpoints.home,
          queryParameters: queryParams,
          cancelToken: token,
        ),
        ApiClient.instance
            .get(ApiEndpoints.performanceTasks, cancelToken: token)
            .catchError((e) {
              debugPrint('Failed to fetch performance tasks: $e');
              return Response(requestOptions: RequestOptions(path: ''));
            }),
      ]);

      final homeResponse = results[0];
      final tasksResponse = results[1];

      dynamic extractTasksPayload(Response? resp) {
        if (resp == null || resp.data == null) return null;
        final data = resp.data;
        if (data is! Map) return null;

        if (data['data'] is Map && data['data']['tasks'] != null) {
          return data['data']['tasks'];
        }
        if (data['tasks'] != null) {
          return data['tasks'];
        }
        if (data['data'] is Map &&
            (data['data']['list'] != null || data['data']['total'] != null)) {
          return data['data'];
        }
        if (data['data'] is List) {
          return data['data'];
        }
        return null;
      }

      dynamic tasksPayload = extractTasksPayload(tasksResponse);
      if (tasksPayload == null ||
          (tasksPayload is Map &&
              (tasksPayload['list'] as List?)?.isEmpty == true) ||
          (tasksPayload is List && tasksPayload.isEmpty)) {
        final homeTasks = extractTasksPayload(homeResponse);
        if (homeTasks != null) {
          tasksPayload = homeTasks;
        }
      }

      if (tasksPayload != null) {
        _tasksSummary = PerformanceTasksSummary.fromJson(tasksPayload);
        _performanceTasks = _tasksSummary!.list;
        await prefs.setString(
          'cached_tasks_summary',
          jsonEncode(_tasksSummary!.toJson()),
        );
      } else {
        _tasksSummary = null;
        _performanceTasks = [];
      }

      if (homeResponse.data != null && homeResponse.data is Map) {
        final rawData = homeResponse.data['data'];
        final Map<String, dynamic> data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : Map<String, dynamic>.from(homeResponse.data);
        var model = HomeDashboardModel.fromJson(data);

        // Merge authoritative attendance status if already loaded from /attendance/status
        if (_statusAttendance != null) {
          final curAtt = model.attendance;
          final mergedCheckIn = (_statusAttendance!.checkInTime.isNotEmpty &&
                  _statusAttendance!.checkInTime != '--:--' &&
                  _statusAttendance!.checkInTime != 'null')
              ? _statusAttendance!.checkInTime
              : (curAtt?.checkInTime ?? '');
          final mergedCheckOut = (_statusAttendance!.checkOutTime.isNotEmpty &&
                  _statusAttendance!.checkOutTime != '--:--' &&
                  _statusAttendance!.checkOutTime != 'null')
              ? _statusAttendance!.checkOutTime
              : (curAtt?.checkOutTime ?? '');
          final mergedShiftStatus = _statusAttendance!.shiftStatus.isNotEmpty
              ? _statusAttendance!.shiftStatus
              : (curAtt?.shiftStatus ?? 'OFFLINE');
          final mergedDate = _statusAttendance!.date.isNotEmpty
              ? _statusAttendance!.date
              : (curAtt?.date ?? '');
          final mergedHours = _statusAttendance!.hoursWorked > 0
              ? _statusAttendance!.hoursWorked
              : (curAtt?.hoursWorked ?? 0.0);

          model = model.copyWith(
            attendance: HomeAttendance(
              checkInTime: mergedCheckIn,
              checkOutTime: mergedCheckOut,
              shiftStatus: mergedShiftStatus,
              isCheckedIn: _statusAttendance!.isCheckedIn,
              isCheckedOut: _statusAttendance!.isCheckedOut,
              date: mergedDate,
              hoursWorked: mergedHours,
              locationLat: _statusAttendance!.locationLat ?? curAtt?.locationLat,
              locationLng: _statusAttendance!.locationLng ?? curAtt?.locationLng,
            ),
          );
        }

        // 1. Sync attendance to AttendanceProvider
        if (model.attendance != null) {
          AttendanceProvider.instance.syncAttendanceFromHome(
            checkedIn: model.attendance!.isCheckedIn,
            checkedOut: model.attendance!.isCheckedOut,
            checkInTimeStr: model.attendance!.checkInTime,
            checkOutTimeStr: model.attendance!.checkOutTime,
            status: model.attendance!.shiftStatus,
          );
        }

        // 2. Sync tasks if returned in home data
        if (model.tasks != null && model.tasks!.list.isNotEmpty) {
          _tasksSummary = PerformanceTasksSummary(
            total: model.tasks!.total,
            completed: model.tasks!.completed,
            pending: model.tasks!.pending,
            list: model.tasks!.list,
          );
          _performanceTasks = _tasksSummary!.list;
          await prefs.setString(
            'cached_tasks_summary',
            jsonEncode(_tasksSummary!.toJson()),
          );
        }

        // 3. Sync ASM role to AuthProvider if designation or dashboard indicates ASM
        final desigLower = model.designationName.toLowerCase();
        final bool isAsm = model.dashboardType?.toUpperCase() == 'ASM' ||
            model.designationName.toUpperCase() == 'ASM' ||
            desigLower.contains('area sales') ||
            desigLower.contains('area manager') ||
            desigLower.contains('area') ||
            desigLower == 'asm' ||
            desigLower.contains('asm');
        if (isAsm && AuthProvider.instance.session.role != 'ASM') {
          AuthProvider.instance.updateSessionRole('ASM');
        }

        // 4. Save fresh data to local cache
        await prefs.setString('cached_home_data', jsonEncode(model.toJson()));

        setState(ApiResponse.success(model));
        return;
      }
      throw Exception('Failed to fetch home dashboard data: empty response');
    } catch (e) {
      if ((e is DioException && CancelToken.isCancel(e)) ||
          (e is ApiException && e.statusCode == 499)) {
        return;
      }

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
        errorMsg =
            'Unable to connect to the server. Please check your internet connection and try again.';
      }

      setState(ApiResponse.error(errorMsg));
    } finally {
      _isFetchingHome = false;
    }
  }
}
