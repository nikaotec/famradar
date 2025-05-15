// lib/models/location_model.dart
import 'package:latlong2/latlong.dart';

class LocationModel {
  final String userId;
  final LatLng position;
  final int timestamp;

  LocationModel({
    required this.userId,
    required this.position,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'latitude': position.latitude,
    'longitude': position.longitude,
    'timestamp': timestamp,
  };

  factory LocationModel.fromMap(Map<String, dynamic> map) => LocationModel(
    userId: map['userId'] as String,
    position: LatLng(map['latitude'] as double, map['longitude'] as double),
    timestamp: map['timestamp'] as int,
  );
}
