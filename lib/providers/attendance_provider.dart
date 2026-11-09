import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/attendance_model.dart';
import '../models/home_dashboard_model.dart';
import '../utils/helpers.dart';
import 'auth_provider.dart';
import 'home_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  static final AttendanceProvider instance = AttendanceProvider._internal();
  AttendanceProvider._internal();

  AttendanceModel _currentAttendance = AttendanceModel.empty();
  HomeAttendance? _todayHomeAttendance;
  HomeAttendance? get todayHomeAttendance => _todayHomeAttendance;

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

  static DateTime _parseTimeString(String str) {
    if (str.isEmpty || str == '--:--' || str == 'null') return DateTime.now();
    try {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) return parsed.toLocal();
    } catch (_) {}
    try {
      final upper = str.toUpperCase().trim();
      final now = DateTime.now();
      if (upper.contains('AM') || upper.contains('PM')) {
        final isPm = upper.contains('PM');
        final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = clean.split(':');
        if (parts.isNotEmpty) {
          int hr = int.tryParse(parts[0].trim()) ?? 0;
          int min = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
          if (isPm && hr < 12) hr += 12;
          if (!isPm && hr == 12) hr = 0;
          return DateTime(now.year, now.month, now.day, hr, min);
        }
      } else {
        final parts = str.split(':');
        if (parts.isNotEmpty) {
          int hr = int.tryParse(parts[0].trim()) ?? 0;
          int min = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
          return DateTime(now.year, now.month, now.day, hr, min);
        }
      }
    } catch (_) {}
    return DateTime.now();
  }

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
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }

        Map<String, dynamic> data = {};
        List<dynamic> todayRecords = [];
        Map<String, dynamic>? record;

        if (rawData is Map) {
          data = Map<String, dynamic>.from(rawData);
          if (data['today_records'] is List) {
            todayRecords = data['today_records'] as List<dynamic>;
          } else if (data['sessions'] is List) {
            todayRecords = data['sessions'] as List<dynamic>;
          } else if (data['punches'] is List) {
            todayRecords = data['punches'] as List<dynamic>;
          } else if (data['attendance'] is Map &&
              (data['attendance']['sessions'] is List ||
                  data['attendance']['punches'] is List)) {
            todayRecords =
                (data['attendance']['sessions'] ??
                        data['attendance']['punches'])
                    as List<dynamic>;
          }
          if (data['record'] is Map) {
            record = Map<String, dynamic>.from(data['record'] as Map);
          } else if (data['attendance'] is Map) {
            record = Map<String, dynamic>.from(data['attendance'] as Map);
            final punches =
                (record['sessions'] is List &&
                    (record['sessions'] as List).isNotEmpty)
                ? (record['sessions'] as List)
                : (record['punches'] is List
                      ? (record['punches'] as List)
                      : null);
            if (punches != null && punches.isNotEmpty && punches.last is Map) {
              final parentHours =
                  record['hours_worked'] ??
                  record['hours_worked_formatted'] ??
                  record['working_hours'];
              final lastPunch = Map<String, dynamic>.from(punches.last as Map);
              record = {...record, ...lastPunch};
              if (UiHelpers.parseWorkingHours(
                        lastPunch['hours_worked'] ??
                            lastPunch['hours_worked_formatted'],
                      ) ==
                      0.0 &&
                  UiHelpers.parseWorkingHours(parentHours) > 0.0) {
                record['hours_worked'] = parentHours;
                record['hours_worked_formatted'] = parentHours;
              }
            }
          } else if (data.containsKey('check_in') ||
              data.containsKey('check_in_time') ||
              data.containsKey('checked_in')) {
            record = Map<String, dynamic>.from(data);
            if (todayRecords.isNotEmpty && todayRecords.last is Map) {
              final parentHours =
                  record['hours_worked'] ??
                  record['hours_worked_formatted'] ??
                  record['working_hours'];
              final lastPunch = Map<String, dynamic>.from(
                todayRecords.last as Map,
              );
              record = {...record, ...lastPunch};
              if (UiHelpers.parseWorkingHours(
                        lastPunch['hours_worked'] ??
                            lastPunch['hours_worked_formatted'],
                      ) ==
                      0.0 &&
                  UiHelpers.parseWorkingHours(parentHours) > 0.0) {
                record['hours_worked'] = parentHours;
                record['hours_worked_formatted'] = parentHours;
              }
            }
          } else if (todayRecords.isNotEmpty && todayRecords.last is Map) {
            record = Map<String, dynamic>.from(todayRecords.last as Map);
          }
        } else if (rawData is List) {
          todayRecords = rawData;
          if (todayRecords.isNotEmpty && todayRecords.last is Map) {
            record = Map<String, dynamic>.from(todayRecords.last as Map);
          }
        }

        final String apiStatus =
            (data['status'] ?? record?['status'] ?? 'absent').toString();
        final String parentDate =
            (data['date'] ??
                    (data['attendance'] is Map
                        ? data['attendance']['date']
                        : null) ??
                    record?['date'] ??
                    '')
                .toString();

        if (todayRecords.isEmpty && record != null) {
          todayRecords = [record];
        }
        final enrichedToday = _enrichTodaySessions(
          todayRecords,
          fallbackDate: parentDate,
          fallbackStatus: apiStatus,
        );
        if (enrichedToday.length >= _todayRecordsList.length ||
            _todayRecordsList.isEmpty) {
          _todayRecordsList = enrichedToday;
        }

        if (record != null) {
          final String checkInTimeStr =
              (record['check_in_time'] ?? record['check_in'] ?? '').toString();
          final checkInTime = _parseTimeString(checkInTimeStr);
          final String checkOutTimeStr =
              (record['check_out_time'] ?? record['check_out'] ?? '')
                  .toString();
          final checkOutTime =
              (checkOutTimeStr.isNotEmpty &&
                  checkOutTimeStr != 'null' &&
                  checkOutTimeStr != '--:--')
              ? _parseTimeString(checkOutTimeStr)
              : null;

          final latVal = record['check_in_lat'] ?? record['latitude'];
          final lngVal = record['check_in_lng'] ?? record['longitude'];
          final double lat = latVal != null
              ? double.tryParse(latVal.toString()) ?? 0.0
              : 0.0;
          final double lng = lngVal != null
              ? double.tryParse(lngVal.toString()) ?? 0.0
              : 0.0;

          final rawHours =
              record['hours_worked'] ??
              record['hours_worked_formatted'] ??
              record['working_hours'];
          double workingHours = UiHelpers.parseWorkingHours(rawHours);

          if (workingHours == 0.0 &&
              checkOutTime != null &&
              checkInTimeStr.isNotEmpty &&
              checkInTimeStr != '--:--') {
            final diffMin = checkOutTime.difference(checkInTime).inMinutes;
            if (diffMin > 0) {
              workingHours = diffMin / 60.0;
            }
          }

          String checkInSelfie =
              (record['check_in_selfie'] ?? record['selfie'] ?? '').toString();
          if (checkInSelfie == 'null') checkInSelfie = '';
          String checkOutSelfie = (record['check_out_selfie'] ?? '').toString();
          if (checkOutSelfie == 'null') checkOutSelfie = '';

          final dynamic rawId = record['id'] ?? record['_id'];

          List<dynamic>? mediaList;
          if (record['media'] is List) {
            mediaList = record['media'] as List<dynamic>;
          }
          if (mediaList == null && todayRecords.isNotEmpty && rawId != null) {
            for (var r in todayRecords) {
              if (r is Map && (r['id'] == rawId || r['_id'] == rawId)) {
                if (r['media'] is List) {
                  mediaList = r['media'] as List<dynamic>;
                  break;
                }
              }
            }
          }

          if (mediaList != null) {
            for (var m in mediaList) {
              if (m is Map) {
                final typeText = m['type_text']?.toString().toLowerCase();
                final filePath = (m['file_path'] ?? m['url'] ?? m['path'])
                    ?.toString();
                if (typeText == 'check-in' || typeText == 'check_in') {
                  checkInSelfie = filePath ?? '';
                } else if (typeText == 'check-out' || typeText == 'check_out') {
                  checkOutSelfie = filePath ?? '';
                }
              }
            }
          }

          final todayKey = (record['date'] ?? '').toString().isNotEmpty
              ? record['date'].toString()
              : DateFormat('yyyy-MM-dd').format(DateTime.now());
          final inTimeLabel = DateFormat(
            'hh:mm a',
          ).format(checkInTime).toUpperCase();
          final outTimeLabel = checkOutTime != null
              ? DateFormat('hh:mm a').format(checkOutTime).toUpperCase()
              : '';

          if (checkInSelfie.isEmpty) {
            checkInSelfie =
                prefs.getString(
                  'attendance_selfie_in_${todayKey}_$inTimeLabel',
                ) ??
                prefs.getString('attendance_selfie_in_$todayKey') ??
                prefs.getString(_keyCheckInSelfie) ??
                _currentAttendance.checkInSelfie;
          }
          if (checkOutTime == null) {
            // Active session has not checked out yet — never inherit previous session's check-out selfie
            checkOutSelfie = '';
          } else if (checkOutSelfie.isEmpty) {
            checkOutSelfie =
                prefs.getString(
                  'attendance_selfie_out_${todayKey}_$outTimeLabel',
                ) ??
                prefs.getString(
                  'attendance_selfie_out_for_in_${todayKey}_$inTimeLabel',
                ) ??
                prefs.getString('attendance_selfie_out_$todayKey') ??
                prefs.getString(_keyCheckOutSelfie) ??
                (_currentAttendance.checkOutSelfie ?? '');
          }

          final rawCheckedIn = record['checked_in'] ?? record['is_checked_in'];
          final rawCheckedOut =
              record['checked_out'] ?? record['is_checked_out'];
          final String recordStatusText =
              (record['shift_status'] ??
                      record['status_text'] ??
                      record['status'] ??
                      apiStatus)
                  .toString();

          final bool isCheckedOut = rawCheckedOut != null
              ? (rawCheckedOut == true ||
                    rawCheckedOut.toString() == '1' ||
                    rawCheckedOut.toString().toLowerCase() == 'true')
              : (apiStatus.toLowerCase() == 'checked_out' ||
                    recordStatusText.toUpperCase() == 'COMPLETED' ||
                    recordStatusText.toUpperCase() == 'CHECKED_OUT' ||
                    (checkOutTimeStr.isNotEmpty &&
                        checkOutTimeStr != '--:--' &&
                        checkOutTimeStr != 'null'));

          final bool isCheckedIn =
              !isCheckedOut &&
              (rawCheckedIn != null
                  ? (rawCheckedIn == true ||
                        rawCheckedIn.toString() == '1' ||
                        rawCheckedIn.toString().toLowerCase() == 'true')
                  : (apiStatus.toLowerCase() == 'checked_in' ||
                        recordStatusText.toUpperCase() == 'ONLINE' ||
                        recordStatusText.toUpperCase() == 'PRESENT' ||
                        (checkInTimeStr.isNotEmpty &&
                            checkInTimeStr != '--:--' &&
                            checkInTimeStr != 'null')));

          String localStatus = 'Absent';
          if (isCheckedOut || recordStatusText.toUpperCase() == 'COMPLETED') {
            localStatus = 'Completed';
          } else if (isCheckedIn ||
              (checkInTimeStr.isNotEmpty && checkInTimeStr != '--:--')) {
            localStatus = 'Present';
          }

          final email = AuthProvider.instance.session.email;
          final emailHash = email.hashCode.abs().toString();
          final fallbackEmpId = email.isNotEmpty
              ? 'EMP_${emailHash.substring(0, emailHash.length > 4 ? 4 : emailHash.length)}'
              : 'EMP_4096';
          final empName =
              (record['name'] ??
                      record['employee_name'] ??
                      (AuthProvider.instance.session.name.isNotEmpty
                          ? AuthProvider.instance.session.name
                          : (email.isNotEmpty
                                ? email.split('@')[0].toUpperCase()
                                : 'SALES OFFICER')))
                  .toString()
                  .trim();
          final empId =
              (record['employee_id'] ?? record['emp_id'] ?? fallbackEmpId)
                  .toString()
                  .trim();

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

          _todayHomeAttendance = HomeAttendance(
            checkInTime: checkInTimeStr,
            checkOutTime: checkOutTimeStr,
            shiftStatus: recordStatusText.isNotEmpty
                ? recordStatusText
                : (isCheckedOut
                      ? 'COMPLETED'
                      : (isCheckedIn ? 'ACTIVE' : 'OFFLINE')),
            isCheckedIn: isCheckedIn,
            isCheckedOut: isCheckedOut,
            date: (record['date'] ?? '').toString(),
            hoursWorked: workingHours,
            locationLat: lat > 0 ? lat : null,
            locationLng: lng > 0 ? lng : null,
          );

          await prefs.setString(_keyStatus, localStatus);
          await prefs.setString(_keyCheckInTime, checkInTime.toIso8601String());
          await prefs.setDouble(_keyCheckInLat, lat);
          await prefs.setDouble(_keyCheckInLng, lng);
          if (checkInSelfie.isNotEmpty) {
            await prefs.setString(_keyCheckInSelfie, checkInSelfie);
            await prefs.setString(
              'attendance_selfie_in_$todayKey',
              checkInSelfie,
            );
            await prefs.setString(
              'attendance_selfie_in_${todayKey}_$inTimeLabel',
              checkInSelfie,
            );
          }
          if (checkOutTime != null) {
            await prefs.setString(
              _keyCheckOutTime,
              checkOutTime.toIso8601String(),
            );
          } else {
            await prefs.remove(_keyCheckOutTime);
            await prefs.remove(_keyCheckOutSelfie);
          }
          if (checkOutSelfie.isNotEmpty && checkOutTime != null) {
            await prefs.setString(_keyCheckOutSelfie, checkOutSelfie);
            await prefs.setString(
              'attendance_selfie_out_$todayKey',
              checkOutSelfie,
            );
            await prefs.setString(
              'attendance_selfie_out_${todayKey}_$outTimeLabel',
              checkOutSelfie,
            );
            await prefs.setString(
              'attendance_selfie_out_for_in_${todayKey}_$inTimeLabel',
              checkOutSelfie,
            );
          }
          await prefs.setDouble(_keyWorkingHours, workingHours);
          await prefs.setString(_keyStatusText, recordStatusText);

          try {
            HomeProvider.instance.updateAttendanceFromStatus(
              checkInTime: checkInTimeStr,
              checkOutTime: checkOutTimeStr,
              shiftStatus: recordStatusText.isNotEmpty
                  ? recordStatusText
                  : (isCheckedOut
                        ? 'COMPLETED'
                        : (isCheckedIn ? 'ACTIVE' : 'OFFLINE')),
              isCheckedIn: isCheckedIn,
              isCheckedOut: isCheckedOut,
              date: (record['date'] ?? '').toString(),
              hoursWorked: workingHours,
            );
          } catch (_) {}
        } else {
          _currentAttendance = AttendanceModel.empty();
          _todayRecordsList = [];
          _todayHomeAttendance = null;
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
    String selfiePath = '',
    required double lat,
    required double lng,
    required String deviceInfo,
    required String sourceMode,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final mapData = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'device_info': deviceInfo,
        'source_mode': sourceMode,
      };
      if (selfiePath.isNotEmpty && File(selfiePath).existsSync()) {
        try {
          mapData['selfie'] = await MultipartFile.fromFile(
            selfiePath,
            filename: selfiePath.split('/').last,
          );
        } catch (_) {}
      }
      final formData = FormData.fromMap(mapData);

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
      await prefs.remove(_keyCheckOutTime);
      await prefs.remove(_keyCheckOutSelfie);
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final inTimeLabel = DateFormat(
        'hh:mm a',
      ).format(checkInTime).toUpperCase();
      await prefs.setString('attendance_selfie_in_$todayKey', selfiePath);
      await prefs.setString(
        'attendance_selfie_in_${todayKey}_$inTimeLabel',
        selfiePath,
      );

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
    String selfiePath = '',
    required double lat,
    required double lng,
  }) async {
    if (_currentAttendance.isAbsent) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      final mapData = <String, dynamic>{'lat': lat, 'lng': lng};
      if (selfiePath.isNotEmpty && File(selfiePath).existsSync()) {
        try {
          mapData['selfie'] = await MultipartFile.fromFile(
            selfiePath,
            filename: selfiePath.split('/').last,
          );
        } catch (_) {}
      }
      final formData = FormData.fromMap(mapData);

      // Call API
      await ApiClient.instance.post(ApiEndpoints.checkOut, data: formData);

      final checkOutTime = DateTime.now();

      // Calculate total hours
      final diff = checkOutTime.difference(_currentAttendance.checkInTime);
      final double workingHours = diff.inMinutes / 60.0; // Return double hours

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
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final outTimeLabel = DateFormat(
        'hh:mm a',
      ).format(checkOutTime).toUpperCase();
      final inTimeLabel = DateFormat(
        'hh:mm a',
      ).format(_currentAttendance.checkInTime).toUpperCase();
      await prefs.setString('attendance_selfie_out_$todayKey', selfiePath);
      await prefs.setString(
        'attendance_selfie_out_${todayKey}_$outTimeLabel',
        selfiePath,
      );
      await prefs.setString(
        'attendance_selfie_out_for_in_${todayKey}_$inTimeLabel',
        selfiePath,
      );
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

  /// Get cached or live selfie path for a specific date
  Future<String?> getSelfieForDate(
    String dateStr, {
    required bool isCheckIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isCheckIn
        ? 'attendance_selfie_in_$dateStr'
        : 'attendance_selfie_out_$dateStr';
    final saved = prefs.getString(key);
    if (saved != null && saved.isNotEmpty) return saved;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (dateStr == todayStr) {
      if (isCheckIn) {
        return _currentAttendance.checkInSelfie.isNotEmpty
            ? _currentAttendance.checkInSelfie
            : prefs.getString(_keyCheckInSelfie);
      } else {
        return (_currentAttendance.checkOutSelfie?.isNotEmpty == true)
            ? _currentAttendance.checkOutSelfie
            : prefs.getString(_keyCheckOutSelfie);
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _enrichTodaySessions(
    List<dynamic> rawList, {
    String fallbackDate = '',
    String fallbackStatus = '',
  }) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final effectiveDate = (fallbackDate.isNotEmpty && fallbackDate != 'null')
        ? fallbackDate
        : todayStr;
    final List<Map<String, dynamic>> enriched = [];

    for (final item in rawList) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      // If item itself is a day wrapper with sessions/punches, unwrap its sessions
      final nestedList =
          (map['sessions'] is List && (map['sessions'] as List).isNotEmpty)
          ? (map['sessions'] as List)
          : ((map['punches'] is List && (map['punches'] as List).isNotEmpty)
                ? (map['punches'] as List)
                : null);

      if (nestedList != null) {
        final dayDate = (map['date'] ?? effectiveDate).toString();
        final dayStatus =
            (map['status'] ?? map['shift_status'] ?? fallbackStatus).toString();
        for (final s in nestedList) {
          if (s is Map) {
            final sessionMap = Map<String, dynamic>.from(s);
            sessionMap['date'] ??= dayDate;
            sessionMap['employee_id'] ??= map['employee_id'];
            sessionMap['name'] ??= map['name'];
            final co =
                (sessionMap['check_out_time'] ?? sessionMap['check_out'] ?? '')
                    .toString()
                    .trim();
            if (sessionMap['status'] == null &&
                sessionMap['status_text'] == null) {
              sessionMap['status'] =
                  (co.isNotEmpty && co != '--:--' && co != 'null')
                  ? 'COMPLETED'
                  : (dayStatus.isNotEmpty && dayStatus.toLowerCase() != 'absent'
                        ? dayStatus
                        : 'ONLINE');
            }
            enriched.add(sessionMap);
          }
        }
      } else {
        map['date'] ??= effectiveDate;
        final co = (map['check_out_time'] ?? map['check_out'] ?? '')
            .toString()
            .trim();
        if (map['status'] == null &&
            map['status_text'] == null &&
            map['shift_status'] == null) {
          map['status'] = (co.isNotEmpty && co != '--:--' && co != 'null')
              ? 'COMPLETED'
              : (fallbackStatus.isNotEmpty &&
                        fallbackStatus.toLowerCase() != 'absent'
                    ? fallbackStatus
                    : 'ONLINE');
        }
        enriched.add(map);
      }
    }
    return enriched;
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
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is List) {
          _historyRecords = rawData;
        } else if (rawData is Map) {
          if (rawData['records'] is Map && rawData['records']['data'] is List) {
            _historyRecords = rawData['records']['data'] as List<dynamic>;
          } else if (rawData['records'] is List) {
            _historyRecords = rawData['records'] as List<dynamic>;
          } else if (rawData['data'] is List) {
            _historyRecords = rawData['data'] as List<dynamic>;
          }
        }

        // Sync today's sessions from history if today's day record is present
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        for (final item in _historyRecords) {
          if (item is Map && (item['date'] ?? '').toString() == todayStr) {
            final todaySessions = _enrichTodaySessions(
              [item],
              fallbackDate: todayStr,
              fallbackStatus: (item['status'] ?? 'ONLINE').toString(),
            );
            if (todaySessions.length >= _todayRecordsList.length) {
              _todayRecordsList = todaySessions;
            }
            break;
          }
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
    _todayHomeAttendance = null;
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

  /// Sync attendance status from Home Dashboard response
  void syncAttendanceFromHome({
    required bool checkedIn,
    required bool checkedOut,
    required String checkInTimeStr,
    required String checkOutTimeStr,
    required String status,
  }) async {
    // If we already have authoritative attendance loaded from /attendance/status, don't overwrite with empty/partial home data
    if (_todayHomeAttendance != null &&
        _todayHomeAttendance!.checkInTime.isNotEmpty &&
        _todayHomeAttendance!.checkInTime != '--:--' &&
        (checkInTimeStr.isEmpty || checkInTimeStr == '--:--')) {
      return;
    }

    String localStatus = 'Absent';
    if (checkedOut) {
      localStatus = 'Completed';
    } else if (checkedIn) {
      localStatus = 'Present';
    }

    final DateTime checkInTime = _parseTimeString(checkInTimeStr);
    final DateTime? checkOutTime =
        (checkedOut &&
            checkOutTimeStr.isNotEmpty &&
            checkOutTimeStr != '--:--' &&
            checkOutTimeStr != 'null')
        ? _parseTimeString(checkOutTimeStr)
        : null;

    _currentAttendance = _currentAttendance.copyWith(
      status: localStatus,
      statusText: status.isNotEmpty ? status : localStatus.toLowerCase(),
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
    );
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStatus, localStatus);
      await prefs.setString(
        _keyStatusText,
        status.isNotEmpty ? status : localStatus.toLowerCase(),
      );
      if (checkedIn) {
        await prefs.setString(_keyCheckInTime, checkInTime.toIso8601String());
      }
      if (checkOutTime != null) {
        await prefs.setString(_keyCheckOutTime, checkOutTime.toIso8601String());
      }
    } catch (_) {}
  }

  /// Clear in-memory attendance state on logout
  void clearData() {
    _currentAttendance = AttendanceModel.empty();
    _todayRecordsList = [];
    _historyRecords = [];
    _todayHomeAttendance = null;
    _isSelfieCaptured = false;
    _selfiePath = '';
    _capturedAt = null;
    _faceDetected = false;
    _faceDetectionStatus = "Align your face in the camera circle";
    notifyListeners();
  }
}
