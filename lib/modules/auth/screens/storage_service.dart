// lib/services/storage_service.dart
import 'package:flutter/services.dart';

abstract class StorageService {
  Future<void> saveUserData(Map<String, String> userData);
}

class NativeStorageService implements StorageService {
  static const platform = MethodChannel('avs.com.famradar/storage');

  @override
  Future<void> saveUserData(Map<String, String> userData) async {
    try {
      await platform.invokeMethod('saveUserData', userData);
    } on PlatformException catch (e) {
      throw Exception('Failed to save user data: ${e.message}');
    }
  }
}
