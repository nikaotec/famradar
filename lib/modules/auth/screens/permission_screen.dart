// lib/modules/permissions/screens/permission_screen.dart
import 'package:famradar/interfaces/permission_servie_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';

class PermissionScreen extends StatefulWidget {
  final PermissionServiceInterface permissionService;

  const PermissionScreen({super.key, required this.permissionService});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  static const platform = MethodChannel('avs.com.famradar/permissions');
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.notification,
      Permission.storage,
    ];

    final statuses = await Future.wait(
      permissions.map(
        (permission) async => MapEntry(permission, await permission.status),
      ),
    );

    setState(() {
      _permissionStatuses = Map.fromEntries(statuses);
    });

    // Check native permissions to ensure consistency
    try {
      final hasAllPermissions = await platform.invokeMethod(
        'hasAllLocationPermissions',
      );
      if (hasAllPermissions == true &&
          _permissionStatuses.values.every((status) => status.isGranted)) {
        context.go('/');
      }
    } on PlatformException catch (e) {
      context.read<AppProvider>().showError(
        'Error checking permissions: ${e.message}',
      );
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Check if we should show rationale dialog
      final shouldShowRationale = await platform.invokeMethod(
        'shouldShowPermissionRationale',
      );
      if (shouldShowRationale == true) {
        // Show native rationale dialog and request permissions
        await platform.invokeMethod('showPermissionRationaleDialog');
      }

      // Request foreground location permissions
      await platform.invokeMethod('requestForegroundLocationPermissions');

      // Request background location permission
      await platform.invokeMethod('requestBackgroundLocationPermission');

      // Request notification permission
      await platform.invokeMethod('requestNotificationPermission');

      // Re-check permissions
      final permissions = [
        Permission.location,
        Permission.locationAlways,
        Permission.notification,
        Permission.storage,
      ];

      final statuses = await Future.wait(
        permissions.map(
          (permission) async => MapEntry(permission, await permission.status),
        ),
      );

      setState(() {
        _permissionStatuses = Map.fromEntries(statuses);
      });

      // Check native permissions
      final hasAllPermissions = await platform.invokeMethod(
        'hasAllLocationPermissions',
      );
      if (hasAllPermissions == true &&
          _permissionStatuses.values.every((status) => status.isGranted)) {
        context.go('/');
      } else {
        context.read<AppProvider>().showError(
          'Please grant all required permissions to use FamRadar.',
        );
      }
    } on PlatformException catch (e) {
      context.read<AppProvider>().showError(
        'Error requesting permissions: ${e.message}',
      );
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await platform.invokeMethod('openAppSettings');
      await _checkPermissions(); // Re-check permissions after returning from settings
    } on PlatformException catch (e) {
      context.read<AppProvider>().showError(
        'Error opening app settings: ${e.message}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions - FamRadar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FamRadar requires the following permissions to function properly:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._permissionStatuses.entries.map(
              (entry) => ListTile(
                leading: Icon(
                  entry.value.isGranted ? Icons.check_circle : Icons.cancel,
                  color: entry.value.isGranted ? Colors.green : Colors.red,
                ),
                title: Text(_getPermissionName(entry.key)),
                subtitle: Text(_getPermissionDescription(entry.key)),
              ),
            ),
            const SizedBox(height: 16),
            if (_permissionStatuses.isNotEmpty &&
                !_permissionStatuses.values.every((status) => status.isGranted))
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _requestPermissions,
                    child: const Text('Grant Permissions'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _openAppSettings,
                    child: const Text('Open App Settings'),
                  ),
                ],
              ),
            if (context.read<AppProvider>().errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  context.read<AppProvider>().errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.location:
      case Permission.locationAlways:
        return 'Location';
      case Permission.notification:
        return 'Notifications';
      case Permission.storage:
        return 'Storage';
      default:
        return 'Unknown';
    }
  }

  String _getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.location:
      case Permission.locationAlways:
        return 'Allows FamRadar to track your location for family monitoring, including in the background.';
      case Permission.notification:
        return 'Enables notifications for alerts and updates.';
      case Permission.storage:
        return 'Required to store user data and settings.';
      default:
        return '';
    }
  }
}
