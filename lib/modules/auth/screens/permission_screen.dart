// lib/modules/permissions/screens/permission_screen.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:famradar/interfaces/storage_service_interface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/user_model.dart';


class PermissionScreen extends StatefulWidget {
  final StorageServiceInterface storageService;
  final Map<String, dynamic>? userData;

  const PermissionScreen({
    super.key,
    required this.storageService,
    this.userData,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  List<Permission> _requiredPermissions = [];
  bool _isLoading = false;
  bool _showWelcome = true;
  String? _osVersion;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    setState(() => _isLoading = true);
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _osVersion = androidInfo.version.sdkInt.toString();
        _requiredPermissions =
            _getRequiredPermissionsForAndroid(androidInfo.version.sdkInt);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _osVersion = iosInfo.systemVersion;
        _requiredPermissions = _getRequiredPermissionsForIOS();
      }
      await _checkPermissions();
    } catch (e) {
      context
          .read<AppProvider>()
          .showError('Erro ao inicializar permissões: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Permission> _getRequiredPermissionsForAndroid(int sdkVersion) {
    final permissions = <Permission>[Permission.location];
    if (sdkVersion >= 29) {
      permissions.add(Permission.locationAlways);
    }
    if (sdkVersion >= 33) {
      permissions.add(Permission.notification);
    }
    if (sdkVersion < 29) {
      permissions.add(Permission.storage);
    }
    return permissions;
  }

  List<Permission> _getRequiredPermissionsForIOS() {
    return [
      Permission.locationWhenInUse,
      Permission.locationAlways,
      Permission.notification,
    ];
  }

  Future<void> _checkPermissions() async {
    final statuses = await Future.wait(
      _requiredPermissions.map(
        (permission) async => MapEntry(permission, await permission.status),
      ),
    );
    setState(() {
      _permissionStatuses = Map.fromEntries(statuses);
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    setState(() => _isLoading = true);
    try {
      if (await permission.shouldShowRequestRationale) {
        final proceed = await _showRationaleDialog(permission);
        if (!proceed) {
          setState(() => _isLoading = false);
          return;
        }
      }
      final status = await permission.request();
      setState(() {
        _permissionStatuses[permission] = status;
      });
      if (status.isPermanentlyDenied) {
        context.read<AppProvider>().showError(
              'Por favor, conceda ${_getPermissionName(permission)} nas configurações do app.',
            );
      }
    } catch (e) {
      context.read<AppProvider>().showError(
            'Erro ao solicitar ${_getPermissionName(permission)}: $e',
          );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showRationaleDialog(Permission permission) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Permitir ${_getPermissionName(permission)}?',
              style: TextStyle(color: Colors.blue.shade900),
            ),
            content: Text(
              _getPermissionDescription(permission),
              style: TextStyle(color: Colors.grey.shade700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text('Negar', style: TextStyle(color: Colors.red.shade700)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Permitir',
                    style: TextStyle(color: Colors.blue.shade700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openAppSettings() async {
    setState(() => _isLoading = true);
    try {
      await openAppSettings();
      await _checkPermissions();
    } catch (e) {
      context.read<AppProvider>().showError(
            'Erro ao abrir configurações do app: $e',
          );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToMapScreen() async {
    setState(() => _isLoading = true);
    try {
      if (widget.userData != null) {
        await widget.storageService.saveUserData(widget.userData!);
        final user = UserModel(
          id: widget.userData!['id']!.toString(),
          name: widget.userData!['name']!.toString(),
          email: widget.userData!['email']!.toString(),
          phone: widget.userData!['phone']?.toString() ?? '',
          photoUrl: widget.userData!['photoUrl']?.toString() ?? '',
        );
        context.read<AppProvider>().setCurrentUser(user);
      }
      context.go('/');
    } catch (e) {
      context
          .read<AppProvider>()
          .showError('Erro ao salvar dados do usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child:
              _showWelcome ? _buildWelcomeScreen() : _buildPermissionScreen(),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom, size: 80, color: Colors.blue.shade700),
          const SizedBox(height: 24),
          Text(
            'Bem-vindo ao FamRadar',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Para manter sua família conectada e segura, precisamos de algumas permissões. Vamos começar!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 32),
          _buildButton(
            onPressed:
                _isLoading ? null : () => setState(() => _showWelcome = false),
            label: 'Começar',
            color: Colors.blue.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionScreen() {
    final grantedCount =
        _permissionStatuses.values.where((status) => status.isGranted).length;
    final totalCount = _requiredPermissions.length;
    final allPermissionsGranted =
        _permissionStatuses.values.every((status) => status.isGranted);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissões ($grantedCount/$totalCount concedidas)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allPermissionsGranted
                ? 'Todas as permissões concedidas! Você está pronto para começar.'
                : 'Por favor, conceda estas permissões para usar o FamRadar.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _requiredPermissions.map((permission) {
                final status =
                    _permissionStatuses[permission] ?? PermissionStatus.denied;
                return Card(
                  elevation: 0,
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(
                      _getPermissionIcon(permission),
                      color: status.isGranted
                          ? Colors.green.shade600
                          : Colors.grey.shade600,
                      size: 32,
                    ),
                    title: Text(
                      _getPermissionName(permission),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    subtitle: Text(
                      _getPermissionDescription(permission),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    trailing: status.isGranted
                        ? Icon(Icons.check_circle, color: Colors.green.shade600)
                        : _buildButton(
                            onPressed: _isLoading
                                ? null
                                : () => status.isPermanentlyDenied
                                    ? _openAppSettings()
                                    : _requestPermission(permission),
                            label: status.isPermanentlyDenied
                                ? 'Configurações'
                                : 'Conceder',
                            color: Colors.blue.shade700,
                            isSmall: true,
                          ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (allPermissionsGranted)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildButton(
                onPressed: _isLoading ? null : _navigateToMapScreen,
                label: 'Continuar para o FamRadar',
                color: Colors.green.shade600,
              ),
            ),
          if (context.read<AppProvider>().errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildErrorCard(context.read<AppProvider>().errorMessage!),
            ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  IconData _getPermissionIcon(Permission permission) {
    if (permission == Permission.location ||
        permission == Permission.locationAlways ||
        permission == Permission.locationWhenInUse) {
      return Icons.location_on;
    } else if (permission == Permission.notification) {
      return Icons.notifications;
    } else if (permission == Permission.storage) {
      return Icons.storage;
    } else {
      return Icons.help;
    }
  }

  String _getPermissionName(Permission permission) {
    if (permission == Permission.location ||
        permission == Permission.locationAlways ||
        permission == Permission.locationWhenInUse) {
      return 'Acesso à Localização';
    } else if (permission == Permission.notification) {
      return 'Notificações';
    } else if (permission == Permission.storage) {
      return 'Acesso ao Armazenamento';
    } else {
      return 'Desconhecido';
    }
  }

  String _getPermissionDescription(Permission permission) {
    if (permission == Permission.location ||
        permission == Permission.locationWhenInUse) {
      return 'Rastreie a localização da sua família em tempo real para segurança e monitoramento.';
    } else if (permission == Permission.locationAlways) {
      return 'Permita acesso à localização em segundo plano para manter o monitoramento ativo.';
    } else if (permission == Permission.notification) {
      return 'Receba alertas e atualizações sobre o status da sua família.';
    } else if (permission == Permission.storage) {
      return 'Salve e acesse dados do app, como configurações e perfis de usuário.';
    } else {
      return '';
    }
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    required Color color,
    bool isSmall = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize:
            isSmall ? const Size(100, 40) : const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmall ? 14 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => context.read<AppProvider>().clearError(),
          ),
        ],
      ),
    );
  }
}
