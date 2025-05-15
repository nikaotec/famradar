// lib/modules/history/models/location_history_model.dart
import 'package:latlong2/latlong.dart';

class LocationHistoryModel {
  final String userId;
  final LatLng position;
  final int timestamp;

  LocationHistoryModel({
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

  factory LocationHistoryModel.fromMap(Map<String, dynamic> map) =>
      LocationHistoryModel(
        userId: map['userId'] as String,
        position: LatLng(map['latitude'] as double, map['longitude'] as double),
        timestamp: map['timestamp'] as int,
      );
}
