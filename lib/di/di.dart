// lib/di/di.dart
import 'package:famradar/interfaces/permission_servie_interface.dart';
import 'package:famradar/modules/geofence/interfaces/geofenceP_service_interface.dart';
import 'package:famradar/modules/history/interfaces/history-service_interface.dart';
import 'package:famradar/modules/invitatiaon/interfaces/invitation_service_interface.dart';
import 'package:famradar/modules/invitatiaon/service/invitation_service.dart';
import 'package:famradar/modules/webrtc/interfaces/signaling_service_interfacace.dart';
import 'package:famradar/modules/webrtc/services/webrtc_sservices.dart';
import 'package:famradar/service/native_storage_service.dart';
import 'package:famradar/service/permission_service.dart';

import '../interfaces/storage_service_interface.dart';
import '../modules/auth/interfaces/auth_service_interface.dart';
import '../modules/webrtc/interfaces/webrtc_service_interface.dart';
import '../modules/chat/interfaces/chat_service_interface.dart';
import '../providers/app_provider.dart';
import '../modules/auth/services/auth_service.dart';
import '../modules/webrtc/services/signaling_service.dart';
import '../modules/geofence/services/geofence_service.dart';
import '../modules/chat/services/chat_service.dart';
import '../modules/history/services/history_service.dart';

class DI {
  static AppProvider createAppProvider() => AppProvider();

  static PermissionServiceInterface createPermissionService(
    AppProvider appProvider,
  ) =>
      PermissionService(appProvider: appProvider);

  static StorageServiceInterface createStorageService(
    AppProvider appProvider,
    PermissionServiceInterface permissionService,
  ) =>
      NativeStorageService(
        appProvider: appProvider,
        permissionService: permissionService,
      );

  static AuthServiceInterface createAuthService(
    AppProvider appProvider,
    StorageServiceInterface storageService,
    PermissionServiceInterface permissionService,
  ) =>
      AuthService(
        appProvider: appProvider,
        storageService: storageService,
        permissionService: permissionService,
      );

  static GeofenceServiceInterface createGeofenceService(
    AppProvider appProvider,
    PermissionServiceInterface permissionService,
  ) =>
      GeofenceService(
        appProvider: appProvider,
        permissionService: permissionService,
      );

  static SignalingServiceInterface createSignalingService(
    AppProvider appProvider,
  ) =>
      SignalingService(appProvider: appProvider);

  static WebRTCServiceInterface createWebRTCService(
    AppProvider appProvider,
    SignalingServiceInterface signalingService,
    PermissionServiceInterface permissionService,
  ) =>
      WebRTCService(
        appProvider: appProvider,
        signalingService: signalingService,
        permissionService: permissionService,
      );

  static ChatServiceInterface createChatService(AppProvider appProvider) =>
      ChatService(appProvider: appProvider);

  static HistoryServiceInterface createHistoryService(
    AppProvider appProvider,
  ) =>
      HistoryService(appProvider: appProvider);

  static InvitationServiceInterface createInvitationService(
    AppProvider appProvider,
  ) =>
      InvitationService(appProvider: appProvider);
}
