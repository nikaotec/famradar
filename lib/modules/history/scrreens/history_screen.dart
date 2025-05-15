// lib/modules/history/screens/history_screen.dart
import 'package:famradar/modules/history/interfaces/history-service_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/location_history_model.dart';

class HistoryScreen extends StatelessWidget {
  final HistoryServiceInterface historyService;
  final String userId;

  const HistoryScreen({
    super.key,
    required this.historyService,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location History')),
      body: StreamBuilder<List<LocationHistoryModel>>(
        stream: historyService.getLocationHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading history'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final locations = snapshot.data!;
          if (locations.isEmpty) {
            return const Center(child: Text('No history available'));
          }
          return FlutterMap(
            options: MapOptions(
              initialCenter: locations.first.position,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'avs.com.famradar',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: locations.map((loc) => loc.position).toList(),
                    strokeWidth: 4,
                    color: Colors.blue,
                  ),
                ],
              ),
              MarkerLayer(
                markers:
                    locations
                        .asMap()
                        .entries
                        .map(
                          (entry) => Marker(
                            point: entry.value.position,
                            child: Icon(
                              Icons.circle,
                              color: entry.key == 0 ? Colors.red : Colors.blue,
                              size: entry.key == 0 ? 16 : 8,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
