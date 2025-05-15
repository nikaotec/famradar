// lib/modules/geofence/interfaces/geofence_s
import 'package:famradar/modules/geofence/models.dart/geofence_model.dart';

abstract class GeofenceServiceInterface {
  Future<void> addGeofence(GeofenceModel geofence);
  Future<List<GeofenceModel>> getGeofences();
}
