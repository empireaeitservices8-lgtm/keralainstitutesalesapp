import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';

class PermissionProvider extends ChangeNotifier {
  static final PermissionProvider instance = PermissionProvider._internal();
  PermissionProvider._internal();

  Map<String, PermissionStatus> _statuses = {};
  bool _isLoading = false;

  Map<String, PermissionStatus> get statuses => _statuses;
  bool get isLoading => _isLoading;

  Future<void> loadStatuses() async {
    _isLoading = true;
    notifyListeners();

    _statuses = await PermissionService.instance.getAllPermissionStatuses();

    _isLoading = false;
    notifyListeners();
  }

  Future<PermissionStatus> requestPermission(
    String name,
    Permission permission,
  ) async {
    final status = await PermissionService.instance.requestPermission(
      permission,
    );
    _statuses[name] = status;
    notifyListeners();
    return status;
  }

  Future<void> requestAll() async {
    _isLoading = true;
    notifyListeners();

    _statuses = await PermissionService.instance.requestAllPermissions();

    _isLoading = false;
    notifyListeners();
  }
}
