// lib/services/native_storage_service.dart
import 'package:famradar/interfaces/permission_servie_interface.dart';
import 'package:flutter/services.dart';
import '../interfaces/storage_service_interface.dart';
import '../providers/app_provider.dart';// Fixed import

class NativeStorageService implements StorageServiceInterface {
  static const _storageChannel = MethodChannel('avs.com.famradar/storage');
  final AppProvider _appProvider;
  final PermissionServiceInterface _permissionService;

  NativeStorageService({
    required AppProvider appProvider,
    required PermissionServiceInterface permissionService,
  }) : _appProvider = appProvider,
       _permissionService = permissionService;

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storageChannel.invokeMethod('saveUserData', userData);
    } catch (e) {
      _appProvider.showError('Error saving user data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final result = await _storageChannel.invokeMethod('getUserData');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      _appProvider.showError('Error fetching user data: $e');
      return null;
    }
  }

  @override
  Future<void> saveLocationSettings(int interval) async {
    try {
      if (await _permissionService.checkPermissions()) {
        await _storageChannel.invokeMethod('saveLocationSettings', {
          'interval': interval,
        });
      } else {
        _appProvider.showError('Location permissions required.');
        await _permissionService.openAppSettings();
      }
    } catch (e) {
      _appProvider.showError('Error saving location settings: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getLocationSettings() async {
    try {
      final result = await _storageChannel.invokeMethod('getLocationSettings');
      return (result as Map?)?.cast<String, dynamic>() ?? {};
    } catch (e) {
      _appProvider.showError('Error fetching location settings: $e');
      return {};
    }
  }

  @override
  Future<void> startLocationService() async {
    try {
      if (await _permissionService.checkPermissions()) {
        await _storageChannel.invokeMethod('startLocationService');
      } else {
        _appProvider.showError('Location permissions required.');
        await _permissionService.openAppSettings();
      }
    } catch (e) {
      _appProvider.showError('Error starting location service: $e');
    }
  }

  @override
  Future<void> stopLocationService() async {
    try {
      await _storageChannel.invokeMethod('stopLocationService');
    } catch (e) {
      _appProvider.showError('Error stopping location service: $e');
    }
  }
}
