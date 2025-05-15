// lib/modules/geofence/services/geofence_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famradar/interfaces/permission_servie_interface.dart';
import 'package:famradar/models/location_model.dart';
import 'package:famradar/modules/geofence/interfaces/geofenceP_service_interface.dart';
import 'package:famradar/modules/geofence/models.dart/geofence_model.dart';
import 'package:famradar/providers/app_provider.dart';
import 'package:flutter/services.dart';// Fixed import

class GeofenceService implements GeofenceServiceInterface {
  static const _geofenceChannel = MethodChannel('avs.com.famradar/geofence');
  static const _eventsChannel = MethodChannel(
    'avs.com.famradar/geofence_events',
  );
  final AppProvider _appProvider;
  final FirebaseFirestore _firestore;
  final PermissionServiceInterface _permissionService;

  GeofenceService({
    required AppProvider appProvider,
    required PermissionServiceInterface permissionService,
    FirebaseFirestore? firestore,
  }) : _appProvider = appProvider,
       _permissionService = permissionService,
       _firestore = firestore ?? FirebaseFirestore.instance {
    _eventsChannel.setMethodCallHandler(_handleEvent);
  }

  Future<void> _handleEvent(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onGeofenceEvent':
          final args = call.arguments as Map?;
          if (args != null) {
            final type = args['type'] as String?;
            final geofenceId = args['geofenceId'] as String?;
            final userId = args['userId'] as String?;
            final timestamp = args['timestamp'] as int?;
            if (type != null && geofenceId != null && timestamp != null) {
              _appProvider.handleGeofenceEvent(
                type: type,
                geofenceId: geofenceId,
                userId: userId,
                timestamp: timestamp,
              );
            } else if (args['latitude'] != null && args['longitude'] != null) {
              _appProvider.updateUserLocation(
                LocationModel.fromMap(args.cast<String, dynamic>()),
              );
            } else {
              _appProvider.showError('Invalid geofence event arguments');
            }
          }
          break;
        case 'onError':
          final args = call.arguments as Map?;
          final errorMessage = args?['errorMessage'] as String?;
          if (errorMessage != null) {
            _appProvider.showError(errorMessage);
          } else {
            _appProvider.showError('Unknown native error');
          }
          break;
        default:
          _appProvider.showError('Unhandled native event: ${call.method}');
      }
    } catch (e) {
      _appProvider.showError('Error processing geofence event: $e');
    }
  }

  @override
  Future<void> addGeofence(GeofenceModel geofence) async {
    try {
      if (await _permissionService.checkPermissions()) {
        await _geofenceChannel.invokeMethod('addGeofence', geofence.toMap());
        await _firestore
            .collection('geofences')
            .doc(geofence.id)
            .set(geofence.toMap());
        _appProvider.addGeofence(geofence);
      } else {
        _appProvider.showError('Location permissions required.');
        await _permissionService.openAppSettings();
      }
    } catch (e) {
      _appProvider.showError('Error adding geofence: $e');
    }
  }

  @override
  Future<List<GeofenceModel>> getGeofences() async {
    try {
      final snapshot = await _firestore.collection('geofences').get();
      final geofences =
          snapshot.docs
              .map((doc) => GeofenceModel.fromMap(doc.data()))
              .toList();
      return geofences;
    } catch (e) {
      _appProvider.showError('Error fetching geofences: $e');
      return [];
    }
  }
}
