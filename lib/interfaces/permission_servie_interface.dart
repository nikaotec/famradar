// lib/interfaces/permission_service_interface.dart

abstract class PermissionServiceInterface {
  Future<bool> requestInitialPermissions();
  Future<bool> checkPermissions();
  Future<void> openAppSettings();
}
