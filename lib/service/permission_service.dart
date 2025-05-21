// lib/services/permission_service.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
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
      final permissions = await _getRequiredPermissions();
      final statuses = await permissions.request();
      final allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        _appProvider.showError(
          'Por favor, conceda todas as permissões necessárias para usar o FamRadar.',
        );
        return false;
      }
      return true;
    } catch (e) {
      _appProvider.showError('Erro ao solicitar permissões: $e');
      return false;
    }
  }

  @override
  Future<bool> checkPermissions() async {
    try {
      final permissions = await _getRequiredPermissions();
      for (var permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          _appProvider.showError('A permissão $permission é necessária.');
          return false;
        }
      }
      return true;
    } catch (e) {
      _appProvider.showError('Erro ao verificar permissões: $e');
      return false;
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      _appProvider.showError('Erro ao abrir configurações do aplicativo: $e');
    }
  }

  Future<List<Permission>> _getRequiredPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final permissions = <Permission>[
        Permission.location,
      ];
      if (androidInfo.version.sdkInt >= 29) {
        permissions.add(Permission.locationAlways);
      }
      if (androidInfo.version.sdkInt >= 33) {
        permissions.add(Permission.notification);
      }
      if (androidInfo.version.sdkInt < 29) {
        permissions.add(Permission.storage);
      }
      return permissions;
    } else {
      return [
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.notification,
      ];
    }
  }
}
