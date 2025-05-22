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
import 'dart:async';

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
  static const eventChannel = EventChannel('avs.com.famradar/location_events');
  final _mapController = MapController();
  LatLng? _initialPosition;
  StreamSubscription<dynamic>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    print('MapScreen initState called');
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
      print('Initial position set from AppProvider: ${_initialPosition.toString()}');
    } else {
      // Fallback para última localização conhecida via NativeBridge
      platform.invokeMethod('getUserData').then((userData) {
        if (userData is Map && userData.containsKey('lastLatitude') && userData.containsKey('lastLongitude')) {
          setState(() {
            _initialPosition = LatLng(
              (userData['lastLatitude'] as num).toDouble(),
              (userData['lastLongitude'] as num).toDouble(),
            );
            print('Initial position set from NativeBridge: ${_initialPosition.toString()}');
          });
        } else {
          setState(() {
            _initialPosition = LatLng(0.0, 0.0);
            print('Initial position set to fallback: (0.0, 0.0)');
          });
        }
      }).catchError((e) {
        print('Error fetching last location: $e');
        setState(() {
          _initialPosition = LatLng(0.0, 0.0);
        });
      });
    }
  }

  Future<void> _startLocationService() async {
    try {
      final userId = context.read<AppProvider>().currentUser?.id;
      if (userId != null) {
        await platform.invokeMethod('startLocationService', {'userId': userId});
        print('Location service started for user: $userId');
      } else {
        print('No user logged in');
        context.read<AppProvider>().showError('Usuário não logado');
      }
    } on PlatformException catch (e) {
      print('Error starting location service: ${e.message}');
      context.read<AppProvider>().showError('Erro ao iniciar serviço de localização: ${e.message}');
    }
  }

  void _listenForEvents() {
    // Atrasar para garantir que o serviço esteja ativo
    Future.delayed(Duration(seconds: 2), () {
      print('Setting up EventChannel listener');
      _eventSubscription = eventChannel.receiveBroadcastStream().listen(
        (event) {
          print('Event received: $event');
          try {
            if (event is Map<dynamic, dynamic>) {
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
                print('Location update received: ${map['latitude']}, ${map['longitude']}');
                // Atualizar última localização no SharedPreferences
                platform.invokeMethod('saveUserData', {
                  'lastLatitude': map['latitude'],
                  'lastLongitude': map['longitude'],
                });
              } else if (map.containsKey('type') && map.containsKey('geofenceId')) {
                context.read<AppProvider>().handleGeofenceEvent(
                      type: map['type'] as String,
                      geofenceId: map['geofenceId'] as String,
                      userId: map['userId'] as String?,
                      timestamp: (map['timestamp'] as num).toInt(),
                    );
                print('Geofence event received: ${map['type']}, ${map['geofenceId']}');
              } else if (map.containsKey('errorMessage')) {
                print('Error event received: ${map['errorMessage']}');
                context.read<AppProvider>().showError(map['errorMessage'] as String);
              } else {
                print('Invalid event format: $map');
              }
            } else {
              print('Event is not a Map: $event');
            }
          } catch (e, stackTrace) {
            print('Error processing event: $e\n$stackTrace');
            context.read<AppProvider>().showError('Erro ao processar atualização: $e');
          }
        },
        onError: (error, stackTrace) {
          print('EventChannel error: $error\n$stackTrace');
          context.read<AppProvider>().showError('Erro no canal de eventos: $error');
        },
        onDone: () {
          print('EventChannel stream closed');
        },
      );
    });
  }

  @override
  void dispose() {
    print('MapScreen dispose called');
    _eventSubscription?.cancel();
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

    // Obter localização do usuário atual
    final userLocation = user != null ? userLocations[user.id] : null;
    final markers = userLocation != null
        ? [
            Marker(
              point: LatLng(userLocation.position.latitude, userLocation.position.longitude),
              width: 50,
              height: 50,
              child: CircleAvatar(
                radius: 25,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                backgroundColor: Colors.blue.shade100,
              ),
            ),
          ]
        : <Marker>[];

    // Atualizar câmera do mapa se a localização mudar
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
                  initialCenter: _initialPosition ?? LatLng(0.0, 0.0),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'avs.com.famradar',
                    errorTileCallback: (tile, error, stackTrace) {
                      print('Tile loading error: $error\n$stackTrace');
                    },
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
                    'Bem-vindo, ${user?.name ?? 'Usuário'}! ${userLocation != null ? 'Lat: ${userLocation.position.latitude.toStringAsFixed(4)}, Lng: ${userLocation.position.longitude.toStringAsFixed(4)}' : 'Obtendo localização...'}',
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