// lib/modules/history/interfaces/history_service_interface.dart
import '../models/location_history_model.dart';

abstract class HistoryServiceInterface {
  Future<void> saveLocation(LocationHistoryModel location);
  Stream<List<LocationHistoryModel>> getLocationHistory(String userId);
}
