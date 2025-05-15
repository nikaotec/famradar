// lib/router.dart
import 'package:famradar/modules/auth/screens/login_scree.dart';
import 'package:famradar/modules/history/scrreens/history_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../di/di.dart';
import '../modules/auth/screens/signup_screen.dart';
import '../modules/chat/screens/chat_screen.dart';
import '../providers/app_provider.dart';
import '../screens/map_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final authService = DI.createAuthService(
      appProvider,
      DI.createStorageService(
        appProvider,
        DI.createPermissionService(appProvider),
      ),
      DI.createPermissionService(appProvider),
    );
    final user = await authService.getCurrentUser();
    if (user != null && state.uri.path == '/login') {
      return '/';
    }
    if (user == null &&
        state.uri.path != '/login' &&
        state.uri.path != '/signup') {
      return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final appProvider = Provider.of<AppProvider>(context);
        return LoginScreen(
          authService: DI.createAuthService(
            appProvider,
            DI.createStorageService(
              appProvider,
              DI.createPermissionService(appProvider),
            ),
            DI.createPermissionService(appProvider),
          ),
        );
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) {
        final appProvider = Provider.of<AppProvider>(context);
        return SignupScreen(
          authService: DI.createAuthService(
            appProvider,
            DI.createStorageService(
              appProvider,
              DI.createPermissionService(appProvider),
            ),
            DI.createPermissionService(appProvider),
          ),
        );
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) {
        final appProvider = Provider.of<AppProvider>(context);
        final permissionService = DI.createPermissionService(appProvider);
        final storageService = DI.createStorageService(
          appProvider,
          permissionService,
        );
        return MapScreen(
          storageService: storageService,
          geofenceService: DI.createGeofenceService(
            appProvider,
            permissionService,
          ),
          webrtcService: DI.createWebRTCService(
            appProvider,
            DI.createSignalingService(appProvider),
            permissionService,
          ),
          authService: DI.createAuthService(
            appProvider,
            storageService,
            permissionService,
          ),
        );
      },
    ),
    GoRoute(
      path: '/chat/:familyId',
      builder: (context, state) {
        final appProvider = Provider.of<AppProvider>(context);
        final familyId = state.pathParameters['familyId']!;
        return ChatScreen(
          chatService: DI.createChatService(appProvider),
          familyId: familyId,
        );
      },
    ),
    GoRoute(
      path: '/history/:userId',
      builder: (context, state) {
        final appProvider = Provider.of<AppProvider>(context);
        final userId = state.pathParameters['userId']!;
        return HistoryScreen(
          historyService: DI.createHistoryService(appProvider),
          userId: userId,
        );
      },
    ),
  ],
);
