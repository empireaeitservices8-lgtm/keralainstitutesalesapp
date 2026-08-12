import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/attendance_model.dart';
import 'auth_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  static final AttendanceProvider instance = AttendanceProvider._internal();
  AttendanceProvider._internal();

  AttendanceModel _currentAttendance = AttendanceModel.empty();
  bool _isLocating = false;
  bool _isSubmitting = false;

  List<dynamic> _todayRecordsList = [];
  List<dynamic> _historyRecords = [];
  bool _isLoadingHistory = false;
  bool _isLoadingToday = false;

  List<dynamic> get todayRecordsList => _todayRecordsList;
  List<dynamic> get historyRecords => _historyRecords;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingToday => _isLoadingToday;

  AttendanceModel get currentAttendance => _currentAttendance;
  bool get isLocating => _isLocating;
  bool get isSubmitting => _isSubmitting;

  // Selfie camera & face detection states
  bool _isSelfieCaptured = false;
  String _selfiePath = '';
  bool _isScanning = false;
  DateTime? _capturedAt;

  bool _isCameraInitialized = false;
  bool _useMockScan = false;
  String _faceDetectionStatus = "Camera starting...";
  bool _faceDetected = false;

  bool get isSelfieCaptured => _isSelfieCaptured;
  String get selfiePath => _selfiePath;
  bool get isScanning => _isScanning;
  DateTime? get capturedAt => _capturedAt;

  bool get isCameraInitialized => _isCameraInitialized;
  bool get useMockScan => _useMockScan;
  String get faceDetectionStatus => _faceDetectionStatus;
  bool get faceDetected => _faceDetected;

  void setSelfieCaptured(bool captured) {
    if (_isSelfieCaptured == captured) return;
    _isSelfieCaptured = captured;
    notifyListeners();
  }

  void setSelfiePath(String path) {
    if (_selfiePath == path) return;
    _selfiePath = path;
    notifyListeners();
  }

  void setScanning(bool scanning) {
    if (_isScanning == scanning) return;
    _isScanning = scanning;
    notifyListeners();
  }

  void setCapturedAt(DateTime? capturedAt) {
    if (_capturedAt == capturedAt) return;
    _capturedAt = capturedAt;
    notifyListeners();
  }

  void setCameraInitialized(bool initialized) {
    if (_isCameraInitialized == initialized) return;
    _isCameraInitialized = initialized;
    notifyListeners();
  }

  void setUseMockScan(bool useMock) {
    if (_useMockScan == useMock) return;
    _useMockScan = useMock;
    notifyListeners();
  }

  void setFaceDetectionStatus(String status) {
    if (_faceDetectionStatus == status) return;
    _faceDetectionStatus = status;
    notifyListeners();
  }

  void setFaceDetected(bool detected) {
    if (_faceDetected == detected) return;
    _faceDetected = detected;
    notifyListeners();
  }

  void resetSelfieState() {
    _isSelfieCaptured = false;
    _selfiePath = '';
    _capturedAt = null;
    _faceDetected = false;
    _faceDetectionStatus = "Align your face in the camera circle";
    notifyListeners();
  }

  // Keys for persistence
  static const String _keyStatus = 'attendance_status';
  static const String _keyCheckInTime = 'attendance_checkin_time';
  static const String _keyCheckInLat = 'attendance_checkin_lat';
  static const String _keyCheckInLng = 'attendance_checkin_lng';
  static const String _keyCheckInSelfie = 'attendance_checkin_selfie';

  static const String _keyCheckOutTime = 'attendance_checkout_time';
  static const String _keyCheckOutSelfie = 'attendance_checkout_selfie';
  static const String _keyWorkingHours = 'attendance_working_hours';
  static const String _keyStatusText = 'attendance_status_text';

  /// Load today's attendance state from SharedPreferences (with live backend synchronization)
  Future<void> loadTodayAttendance({bool isRefresh = false}) async {
    if (!isRefresh && _todayRecordsList.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    // 1. Load cached state first for immediate UI responsiveness
    final cachedStatus = prefs.getString(_keyStatus) ?? 'Absent';
    if (cachedStatus == 'Absent') {
      _currentAttendance = AttendanceModel.empty();
    } else {
      final checkInTimeStr = prefs.getString(_keyCheckInTime) ?? '';
      final checkInTime = checkInTimeStr.isNotEmpty
          ? DateTime.parse(checkInTimeStr)
          : DateTime.now();
      final lat = prefs.getDouble(_keyCheckInLat) ?? 0.0;
      final lng = prefs.getDouble(_keyCheckInLng) ?? 0.0;
      final selfie = prefs.getString(_keyCheckInSelfie) ?? '';

      final checkOutTimeStr = prefs.getString(_keyCheckOutTime) ?? '';
      final checkOutTime = checkOutTimeStr.isNotEmpty
          ? DateTime.parse(checkOutTimeStr)
          : null;
      final checkoutSelfie = prefs.getString(_keyCheckOutSelfie) ?? '';
      final workingHours = prefs.getDouble(_keyWorkingHours);
      final statusText = prefs.getString(_keyStatusText) ?? 'pending';

      final email = AuthProvider.instance.session.email;
      final empName = email.isNotEmpty
          ? email.split('@')[0].toUpperCase()
          : 'SALES OFFICER';
      final empId = email.isNotEmpty
          ? 'EMP_${email.hashCode.abs().toString().substring(0, 4)}'
          : 'EMP_4096';

      _currentAttendance = AttendanceModel(
        employeeId: empId,
        employeeName: empName,
        checkInSelfie: selfie,
        checkInTime: checkInTime,
        checkInLatitude: lat,
        checkInLongitude: lng,
        checkOutTime: checkOutTime,
        checkOutSelfie: checkoutSelfie.isEmpty ? null : checkoutSelfie,
        workingHours: workingHours,
        status: cachedStatus,
        statusText: statusText,
      );
    }
    notifyListeners();

    // 2. Perform live network sync check-in backend
    _isLoadingToday = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.attendanceStatus,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final String apiStatus = data['status'] as String? ?? 'absent';

        final todayRecords = data['today_records'] as List<dynamic>?;
        _todayRecordsList = todayRecords ?? [];
        final record = data['record'] as Map<String, dynamic>? ??
            (todayRecords != null && todayRecords.isNotEmpty
                ? todayRecords.last as Map<String, dynamic>?
                : null);

        if (record != null) {
          final String checkInTimeStr =
              record['check_in_time'] as String? ?? '';
          final checkInTime = checkInTimeStr.isNotEmpty
              ? DateTime.parse(checkInTimeStr)
              : DateTime.now();
          final String checkOutTimeStr =
              record['check_out_time'] as String? ?? '';
          final checkOutTime = checkOutTimeStr.isNotEmpty
              ? DateTime.parse(checkOutTimeStr)
              : null;

          final latVal = record['check_in_lat'];
          final lngVal = record['check_in_lng'];
          final double lat = latVal != null
              ? double.tryParse(latVal.toString()) ?? 0.0
              : 0.0;
          final double lng = lngVal != null
              ? double.tryParse(lngVal.toString()) ?? 0.0
              : 0.0;

          final String hoursStr = record['hours_worked'] as String? ?? '0.0';
          final double workingHours = (double.tryParse(hoursStr) ?? 0.0).abs();

          String checkInSelfie = '';
          String checkOutSelfie = '';

          final int recordId = record['id'] as int? ?? 0;

          List<dynamic>? mediaList = record['media'] as List<dynamic>?;
          if (mediaList == null && todayRecords != null && recordId != 0) {
            for (var r in todayRecords) {
              if (r is Map<String, dynamic> && r['id'] == recordId) {
                mediaList = r['media'] as List<dynamic>?;
                break;
              }
            }
          }

          if (mediaList != null) {
            for (var m in mediaList) {
              if (m is Map<String, dynamic>) {
                final typeText = m['type_text'] as String?;
                final filePath = m['file_path'] as String?;
                if (typeText == 'check-in') {
                  checkInSelfie = filePath ?? '';
                } else if (typeText == 'check-out') {
                  checkOutSelfie = filePath ?? '';
                }
              }
            }
          }

          String localStatus = 'Absent';
          if (apiStatus == 'checked_in') {
            localStatus = 'Present';
          } else if (apiStatus == 'checked_out') {
            localStatus = 'Completed';
          }

          final String recordStatusText = record['status_text'] as String? ?? 'pending';

          final email = AuthProvider.instance.session.email;
          final empName = email.isNotEmpty
              ? email.split('@')[0].toUpperCase()
              : 'SALES OFFICER';
          final emailHash = email.hashCode.abs().toString();
          final empId = email.isNotEmpty
              ? 'EMP_${emailHash.substring(0, emailHash.length > 4 ? 4 : emailHash.length)}'
              : 'EMP_4096';

          _currentAttendance = AttendanceModel(
            employeeId: empId,
            employeeName: empName,
            checkInSelfie: checkInSelfie,
            checkInTime: checkInTime,
            checkInLatitude: lat,
            checkInLongitude: lng,
            checkOutTime: checkOutTime,
            checkOutSelfie: checkOutSelfie.isEmpty ? null : checkOutSelfie,
            workingHours: workingHours,
            status: localStatus,
            statusText: recordStatusText,
          );

          await prefs.setString(_keyStatus, localStatus);
          await prefs.setString(_keyCheckInTime, checkInTime.toIso8601String());
          await prefs.setDouble(_keyCheckInLat, lat);
          await prefs.setDouble(_keyCheckInLng, lng);
          await prefs.setString(_keyCheckInSelfie, checkInSelfie);
          if (checkOutTime != null) {
            await prefs.setString(
              _keyCheckOutTime,
              checkOutTime.toIso8601String(),
            );
          }
          await prefs.setString(_keyCheckOutSelfie, checkOutSelfie);
          await prefs.setDouble(_keyWorkingHours, workingHours);
          await prefs.setString(_keyStatusText, recordStatusText);
        } else {
          _currentAttendance = AttendanceModel.empty();
          _todayRecordsList = [];
          await prefs.setString(_keyStatus, 'Absent');

          await prefs.remove(_keyCheckInTime);
          await prefs.remove(_keyCheckInLat);
          await prefs.remove(_keyCheckInLng);
          await prefs.remove(_keyCheckInSelfie);
          await prefs.remove(_keyCheckOutTime);
          await prefs.remove(_keyCheckOutSelfie);
          await prefs.remove(_keyWorkingHours);
          await prefs.remove(_keyStatusText);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        "Failed to fetch online attendance status ($e). Using cached local state.",
      );
    } finally {
      _isLoadingToday = false;
      notifyListeners();
    }
  }

  /// Perform Check-In
  Future<bool> checkIn({
    required String selfiePath,
    required double lat,
    required double lng,
    required String deviceInfo,
    required String sourceMode,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'device_info': deviceInfo,
        'source_mode': sourceMode,
        'selfie': await MultipartFile.fromFile(
          selfiePath,
          filename: selfiePath.split('/').last,
        ),
      });

      // Call API
      await ApiClient.instance.post(ApiEndpoints.checkIn, data: formData);

      final email = AuthProvider.instance.session.email;
      final empName = email.isNotEmpty
          ? email.split('@')[0].toUpperCase()
          : 'SALES OFFICER';
      final empId = email.isNotEmpty
          ? 'EMP_${email.hashCode.abs().toString().substring(0, 4)}'
          : 'EMP_4096';
      final checkInTime = DateTime.now();

      // Update model
      _currentAttendance = AttendanceModel(
        employeeId: empId,
        employeeName: empName,
        checkInSelfie: selfiePath,
        checkInTime: checkInTime,
        checkInLatitude: lat,
        checkInLongitude: lng,
        status: 'Present',
      );

      // Persist details
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStatus, 'Present');
      await prefs.setString(_keyCheckInTime, checkInTime.toIso8601String());
      await prefs.setDouble(_keyCheckInLat, lat);
      await prefs.setDouble(_keyCheckInLng, lng);
      await prefs.setString(_keyCheckInSelfie, selfiePath);

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      debugPrint('Check-In API request failed: $e');
      rethrow;
    }
  }

  /// Perform Check-Out
  Future<bool> checkOut({
    required String selfiePath,
    required double lat,
    required double lng,
  }) async {
    if (_currentAttendance.isAbsent) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'selfie': await MultipartFile.fromFile(
          selfiePath,
          filename: selfiePath.split('/').last,
        ),
      });

      // Call API
      await ApiClient.instance.post(ApiEndpoints.checkOut, data: formData);

      final checkOutTime = DateTime.now();

      // Calculate total hours
      final diff = checkOutTime.difference(_currentAttendance.checkInTime);
      final double workingHours =
          diff.inMinutes / 60.0; // Return double hours

      // Update model
      _currentAttendance = _currentAttendance.copyWith(
        checkOutSelfie: selfiePath,
        checkOutTime: checkOutTime,
        workingHours: workingHours,
        status: 'Completed',
      );

      // Persist details
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStatus, 'Completed');
      await prefs.setString(_keyCheckOutTime, checkOutTime.toIso8601String());
      await prefs.setString(_keyCheckOutSelfie, selfiePath);
      await prefs.setDouble(_keyWorkingHours, workingHours);

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      debugPrint('Check-Out API request failed: $e');
      rethrow;
    }
  }

  /// Fetch online attendance history (all days)
  Future<void> loadAttendanceHistory({bool isRefresh = false}) async {
    if (!isRefresh && _historyRecords.isNotEmpty) return;
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.attendanceHistory,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final recordsMap = data['records'] as Map<String, dynamic>?;
        if (recordsMap != null) {
          _historyRecords = recordsMap['data'] as List<dynamic>? ?? [];
        }
      }
    } catch (e) {
      debugPrint('Failed to load attendance history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Reset helper for testing/debugging purposes
  Future<void> resetAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStatus);
    await prefs.remove(_keyCheckInTime);
    await prefs.remove(_keyCheckInLat);
    await prefs.remove(_keyCheckInLng);
    await prefs.remove(_keyCheckInSelfie);
    await prefs.remove(_keyCheckOutTime);
    await prefs.remove(_keyCheckOutSelfie);
    await prefs.remove(_keyWorkingHours);

    _currentAttendance = AttendanceModel.empty();
    notifyListeners();
  }

  /// Geolocation locator checker
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (_) {
      return null;
    }
  }

  /// Clear in-memory attendance state on logout
  void clearData() {
    _currentAttendance = AttendanceModel.empty();
    _todayRecordsList = [];
    _historyRecords = [];
    _isSelfieCaptured = false;
    _selfiePath = '';
    _capturedAt = null;
    _faceDetected = false;
    _faceDetectionStatus = "Align your face in the camera circle";
    notifyListeners();
  }
}
