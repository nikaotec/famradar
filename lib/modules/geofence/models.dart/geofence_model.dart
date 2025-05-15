// lib/modules/geofence/models/geofence_model.dart
class GeofenceModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;

  GeofenceModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
  };

  factory GeofenceModel.fromMap(Map<String, dynamic> map) => GeofenceModel(
    id: map['id'] as String,
    name: map['name'] as String,
    latitude: map['latitude'] as double,
    longitude: map['longitude'] as double,
    radius: map['radius'] as double,
  );
}
