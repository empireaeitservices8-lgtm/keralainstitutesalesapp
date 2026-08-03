import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import 'auth_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  static final AttendanceProvider instance = AttendanceProvider._internal();
  AttendanceProvider._internal();

  AttendanceModel _currentAttendance = AttendanceModel.empty();
  bool _isLocating = false;
  bool _isSubmitting = false;

  AttendanceModel get currentAttendance => _currentAttendance;
  bool get isLocating => _isLocating;
  bool get isSubmitting => _isSubmitting;

  // Keys for persistence
  static const String _keyStatus = 'attendance_status';
  static const String _keyCheckInTime = 'attendance_checkin_time';
  static const String _keyCheckInLat = 'attendance_checkin_lat';
  static const String _keyCheckInLng = 'attendance_checkin_lng';
  static const String _keyCheckInSelfie = 'attendance_checkin_selfie';
  
  static const String _keyCheckOutTime = 'attendance_checkout_time';
  static const String _keyCheckOutSelfie = 'attendance_checkout_selfie';
  static const String _keyWorkingHours = 'attendance_working_hours';

  /// Load today's attendance state from SharedPreferences
  Future<void> loadTodayAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_keyStatus) ?? 'Absent';
    
    if (status == 'Absent') {
      _currentAttendance = AttendanceModel.empty();
    } else {
      final checkInTimeStr = prefs.getString(_keyCheckInTime) ?? '';
      final checkInTime = checkInTimeStr.isNotEmpty ? DateTime.parse(checkInTimeStr) : DateTime.now();
      final lat = prefs.getDouble(_keyCheckInLat) ?? 0.0;
      final lng = prefs.getDouble(_keyCheckInLng) ?? 0.0;
      final selfie = prefs.getString(_keyCheckInSelfie) ?? '';
      
      final checkOutTimeStr = prefs.getString(_keyCheckOutTime) ?? '';
      final checkOutTime = checkOutTimeStr.isNotEmpty ? DateTime.parse(checkOutTimeStr) : null;
      final checkoutSelfie = prefs.getString(_keyCheckOutSelfie) ?? '';
      final workingHours = prefs.getDouble(_keyWorkingHours);

      // Fetch employee info
      final email = AuthProvider.instance.session.email;
      final empName = email.isNotEmpty ? email.split('@')[0].toUpperCase() : 'SALES OFFICER';
      final empId = email.isNotEmpty ? 'EMP_${email.hashCode.abs().toString().substring(0, 4)}' : 'EMP_4096';

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
        status: status,
      );
    }
    notifyListeners();
  }

  /// Perform Check-In
  Future<bool> checkIn(String selfiePath) async {
    _isLocating = true;
    _isSubmitting = true;
    notifyListeners();

    // 1. Get position
    double lat = 10.0159; // Default Kochi, Kerala Lat
    double lng = 76.3419; // Default Kochi, Kerala Lng
    
    try {
      final position = await _determinePosition();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (_) {
      // Fallback silently to Kochi mock coordinates
    }

    _isLocating = false;
    notifyListeners();

    // 2. Mock API delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final email = AuthProvider.instance.session.email;
    final empName = email.isNotEmpty ? email.split('@')[0].toUpperCase() : 'SALES OFFICER';
    final empId = email.isNotEmpty ? 'EMP_${email.hashCode.abs().toString().substring(0, 4)}' : 'EMP_4096';
    final checkInTime = DateTime.now();

    // 3. Update model
    _currentAttendance = AttendanceModel(
      employeeId: empId,
      employeeName: empName,
      checkInSelfie: selfiePath,
      checkInTime: checkInTime,
      checkInLatitude: lat,
      checkInLongitude: lng,
      status: 'Present',
    );

    // 4. Persist details
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStatus, 'Present');
    await prefs.setString(_keyCheckInTime, checkInTime.toIso8601String());
    await prefs.setDouble(_keyCheckInLat, lat);
    await prefs.setDouble(_keyCheckInLng, lng);
    await prefs.setString(_keyCheckInSelfie, selfiePath);

    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  /// Perform Check-Out
  Future<bool> checkOut(String selfiePath) async {
    if (_currentAttendance.isAbsent) return false;

    _isSubmitting = true;
    notifyListeners();

    // Mock API delay
    await Future.delayed(const Duration(milliseconds: 1500));

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
    await prefs.setDouble(_keyWorkingHours, workingHours);

    _isSubmitting = false;
    notifyListeners();
    return true;
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
}
