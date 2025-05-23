import 'package:famradar/modules/geofence/interfaces/geofenceP_service_interface.dart';
import 'package:famradar/modules/geofence/models.dart/geofence_model.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class GeofenceScreen extends StatefulWidget {
  final GeofenceServiceInterface geofenceService;
  final LatLng initialPosition;

  const GeofenceScreen({
    super.key,
    required this.geofenceService,
    required this.initialPosition,
  });

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _radiusController = TextEditingController();
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialPosition.latitude;
    _longitude = widget.initialPosition.longitude;
    _radiusController.text = '100';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _addGeofence() async {
    if (_formKey.currentState!.validate()) {
      final geofence = GeofenceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: _latitude,
        longitude: _longitude,
        radius: double.parse(_radiusController.text),
        name: _nameController.text,
      );
      try {
        await widget.geofenceService.addGeofence(geofence);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geofence "${geofence.name}" adicionado!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar geofence: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Geofence'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome do Geofence',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite um nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _latitude.toString(),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _latitude = double.tryParse(value) ?? _latitude;
                },
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Digite uma latitude válida';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _longitude.toString(),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _longitude = double.tryParse(value) ?? _longitude;
                },
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Digite uma longitude válida';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _radiusController,
                decoration: InputDecoration(
                  labelText: 'Raio (metros)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Digite um raio válido (> 0)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addGeofence,
                child: Text('Adicionar Geofence'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
