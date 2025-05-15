// lib/interfaces/storage_service_interface.dart
abstract class StorageServiceInterface {
  Future<void> saveUserData(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData();
  Future<void> saveLocationSettings(int interval);
  Future<Map<String, dynamic>> getLocationSettings();
  Future<void> startLocationService();
  Future<void> stopLocationService();
}
