// lib/router.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:famradar/di/di.dart' show DI;
import 'package:famradar/modules/auth/screens/login_screen.dart';
import 'package:famradar/modules/auth/screens/permission_screen.dart';
import 'package:famradar/modules/auth/screens/signup_screen.dart';
import 'package:famradar/modules/auth/screens/storage_service.dart';
import 'package:famradar/providers/app_provider.dart';
import 'package:famradar/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final userData = state.extra as Map<String, dynamic>?;
        return PermissionScreen(
          storageService: DI.createStorageService(
            appProvider,
            DI.createPermissionService(appProvider),
          ),
          userData: userData,
        );
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final permissionService = DI.createPermissionService(appProvider);
        final storageService =
            DI.createStorageService(appProvider, permissionService);
        return MapScreen(
          storageService: storageService,
          geofenceService:
              DI.createGeofenceService(appProvider, permissionService),
          webrtcService: DI.createWebRTCService(
            appProvider,
            DI.createSignalingService(appProvider),
            permissionService,
          ),
          authService: DI.createAuthService(
              appProvider, storageService, permissionService),
        );
      },
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) async {
    final requiredPermissions = Platform.isAndroid
        ? [
            Permission.location,
            if (await DeviceInfoPlugin()
                .androidInfo
                .then((info) => info.version.sdkInt >= 29))
              Permission.locationAlways,
            if (await DeviceInfoPlugin()
                .androidInfo
                .then((info) => info.version.sdkInt >= 33))
              Permission.notification,
            if (await DeviceInfoPlugin()
                .androidInfo
                .then((info) => info.version.sdkInt < 29))
              Permission.storage,
          ]
        : [
            Permission.locationWhenInUse,
            Permission.locationAlways,
            Permission.notification,
          ];

    final allPermissionsGranted = await Future.wait(
      requiredPermissions.map((p) => p.status),
    ).then((statuses) => statuses.every((s) => s.isGranted));

    if (!allPermissionsGranted &&
        state.uri.toString() != '/permissions' &&
        state.uri.toString() != '/login' &&
        state.uri.toString() != '/signup') {
      return '/permissions';
    }

    return null;
  },
);
