// lib/modules/map/screens/map_screen.dart
import 'package:famradar/modules/auth/interfaces/auth_service_interface.dart';
import 'package:famradar/modules/geofence/interfaces/geofenceP_service_interface.dart';
import 'package:famradar/modules/webrtc/interfaces/webrtc_service_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/location_model.dart';
import '../../interfaces/storage_service_interface.dart';

class MapScreen extends StatefulWidget {
  final StorageServiceInterface storageService;
  final GeofenceServiceInterface geofenceService;
  final WebRTCServiceInterface webrtcService;
  final AuthServiceInterface authService;

  const MapScreen({
    super.key,
    required this.storageService,
    required this.geofenceService,
    required this.webrtcService,
    required this.authService,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const platform = MethodChannel('avs.com.famradar/storage');
  static const eventChannel = EventChannel('avs.com.famradar/geofence_events');
  final _mapController = MapController();
  LatLng? _initialPosition; // Will be set to user's location

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
    _startLocationService();
    _listenForEvents();
  }

  void _setInitialPosition() {
    final user = context.read<AppProvider>().currentUser;
    final userLocations = context.read<AppProvider>().userLocations;
    if (user != null && userLocations.containsKey(user.id)) {
      final userLocation = userLocations[user.id]!;
      _initialPosition = LatLng(userLocation.position.latitude, userLocation.position.longitude);
    } else {
      _initialPosition =
          LatLng(-8.0395, -34.9466); // Fallback: Recife, based on logs
    }
  }

  Future<void> _startLocationService() async {
    try {
      final userId = context.read<AppProvider>().currentUser?.id;
      if (userId != null) {
        await platform.invokeMethod('startLocationService', {'userId': userId});
        print('Location service started for user: $userId');
      } else {
        context.read<AppProvider>().showError('User not logged in');
      }
    } catch (e) {
      context
          .read<AppProvider>()
          .showError('Error starting location service: $e');
    }
  }

  void _listenForEvents() {
    eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          if (event is Map) {
            final map = event.cast<String, dynamic>();
            if (map.containsKey('latitude') &&
                map.containsKey('longitude') &&
                map['latitude'] is double &&
                map['longitude'] is double &&
                map['timestamp'] is int) {
              context.read<AppProvider>().handleLocationUpdate(
                    userId: (map['userId'] as String?) ?? '',
                    latitude: map['latitude'] as double,
                    longitude: map['longitude'] as double,
                    timestamp: map['timestamp'] as int,
                  );
              print(
                  'Received location update: ${map['latitude']}, ${map['longitude']}');
            } else if (map.containsKey('error')) {
              context.read<AppProvider>().showError(map['error'] as String);
            } else {
              print('Invalid event format: $map');
            }
          } else {
            print('Event is not a Map: $event');
          }
        } catch (e) {
          context.read<AppProvider>().showError('Error processing event: $e');
        }
      },
      onError: (error) {
        context.read<AppProvider>().showError('Event channel error: $error');
      },
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    platform.invokeMethod('stopLocationService').catchError((e) {
      print('Error stopping location service: $e');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final userLocations = context.watch<AppProvider>().userLocations;

    // Get the current user's location
    final userLocation = user != null ? userLocations[user.id] : null;
    final markers = userLocation != null
        ? [
            Marker(
              point: LatLng(
                  userLocation.position.latitude, userLocation.position.longitude),
              width: 50,
              height: 50,
              child: CircleAvatar(
                radius: 25,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
                backgroundColor: Colors.blue.shade100,
              ),
            ),
          ]
        : <Marker>[];

    // Update map camera if location changes
    if (userLocation != null) {
      _mapController.move(
        LatLng(userLocation.position.latitude, userLocation.position.longitude),
        14,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialPosition ?? LatLng(-8.0395, -34.9466),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=YOUR_MAPTILER_API_KEY',
                    userAgentPackageName: 'avs.com.famradar',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Welcome, ${user?.name ?? 'User'}! ${userLocation != null ? 'Lat: ${userLocation.position.latitude.toStringAsFixed(4)}, Lng: ${userLocation.position.longitude.toStringAsFixed(4)}' : 'Fetching location...'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
