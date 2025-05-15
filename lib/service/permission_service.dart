// lib/services/permission_service.dart
import 'package:famradar/interfaces/permission_servie_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_provider.dart';

class PermissionService implements PermissionServiceInterface {
  final AppProvider _appProvider;

  PermissionService({required AppProvider appProvider})
    : _appProvider = appProvider;

  @override
  Future<bool> requestInitialPermissions() async {
    try {
      final permissions = [
        Permission.location,
        Permission.locationAlways,
        Permission.notification,
        Permission.storage,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        _appProvider.showError(
          'Please grant all required permissions to use FamRadar.',
        );
        return false;
      }

      return true;
    } catch (e) {
      _appProvider.showError('Error requesting permissions: $e');
      return false;
    }
  }

  @override
  Future<bool> checkPermissions() async {
    try {
      final permissions = [
        Permission.location,
        Permission.locationAlways,
        Permission.notification,
        Permission.storage,
      ];

      for (var permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          _appProvider.showError('Permission $permission is required.');
          return false;
        }
      }
      return true;
    } catch (e) {
      _appProvider.showError('Error checking permissions: $e');
      return false;
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      _appProvider.showError('Error opening app settings: $e');
    }
  }
}
