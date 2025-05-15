// lib/screens/map_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:famradar/modules/geofence/interfaces/geofenceP_service_interface.dart';
import 'package:famradar/modules/geofence/models.dart/geofence_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../modules/auth/interfaces/auth_service_interface.dart';
import '../modules/webrtc/interfaces/webrtc_service_interface.dart';
import '../interfaces/storage_service_interface.dart';
import '../providers/app_provider.dart';

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
  @override
  void initState() {
    super.initState();
    widget.storageService.startLocationService();
  }

  @override
  void dispose() {
    widget.storageService.stopLocationService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FamRadar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () => context.go('/chat/test_family'),
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed:
                    () => context.go(
                      '/history/${appProvider.currentUser?.id ?? ""}',
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await widget.authService.signOut();
                  context.go('/login');
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter:
                      appProvider.userLocations.isNotEmpty
                          ? appProvider.userLocations.values.first.position
                          : const LatLng(0, 0),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'avs.com.famradar',
                  ),
                  MarkerLayer(
                    markers:
                        appProvider.familyMembers.entries
                            .where(
                              (entry) => appProvider.userLocations.containsKey(
                                entry.key,
                              ),
                            )
                            .map(
                              (entry) => Marker(
                                point:
                                    appProvider
                                        .userLocations[entry.key]!
                                        .position,
                                width: 50,
                                height: 50,
                                child: GestureDetector(
                                  onTap:
                                      () => ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(entry.value.name),
                                        ),
                                      ),
                                  child: CircleAvatar(
                                    backgroundImage:
                                        entry.value.photoUrl != null
                                            ? CachedNetworkImageProvider(
                                              entry.value.photoUrl!,
                                            )
                                            : null,
                                    child:
                                        entry.value.photoUrl == null
                                            ? Text(entry.value.name[0])
                                            : null,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  CircleLayer(
                    circles:
                        appProvider.geofences.entries
                            .map(
                              (entry) => CircleMarker(
                                point: LatLng(
                                  entry.value.latitude,
                                  entry.value.longitude,
                                ),
                                radius: entry.value.radius,
                                color: Colors.green.withOpacity(0.3),
                                borderColor: Colors.green,
                                borderStrokeWidth: 2,
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
              if (appProvider.errorMessage != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              appProvider.errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: appProvider.clearError,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final geofence = GeofenceModel(
                id: 'geofence_${DateTime.now().millisecondsSinceEpoch}',
                name: 'Test Location',
                latitude: 0.0,
                longitude: 0.0,
                radius: 100.0,
              );
              await widget.geofenceService.addGeofence(geofence);
              if (appProvider.currentUser != null) {
                await widget.webrtcService.startWebRTCConnection('test_user');
              }
            },
            child: const Icon(Icons.add_location),
          ),
        );
      },
    );
  }
}
