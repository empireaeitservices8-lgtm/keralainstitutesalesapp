import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._internal();
  PermissionService._internal();

  /// Map representation of our target permissions for UI convenience
  final Map<String, Permission> appPermissions = {
    'Location': Permission.location,
    'Camera': Permission.camera,
    'Storage': Permission.storage,
    'Notifications': Permission.notification,
  };

  /// Get status of a specific permission
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    return await permission.status;
  }

  /// Request a specific permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  /// Check statuses of all required permissions
  Future<Map<String, PermissionStatus>> getAllPermissionStatuses() async {
    final Map<String, PermissionStatus> statuses = {};
    for (var entry in appPermissions.entries) {
      statuses[entry.key] = await entry.value.status;
    }
    return statuses;
  }

  /// Request all permissions sequentially or in batch
  Future<Map<String, PermissionStatus>> requestAllPermissions() async {
    final List<Permission> list = appPermissions.values.toList();
    final Map<Permission, PermissionStatus> results = await list.request();
    
    final Map<String, PermissionStatus> nameResults = {};
    appPermissions.forEach((name, permission) {
      nameResults[name] = results[permission] ?? PermissionStatus.denied;
    });
    return nameResults;
  }

  /// Opens the app settings screen in OS settings
  Future<bool> openAppSettingsScreen() async {
    return await openAppSettings();
  }
}
