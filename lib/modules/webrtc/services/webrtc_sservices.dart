// lib/modules/webrtc/services/webrtc_service.dart
import 'package:famradar/interfaces/permission_servie_interface.dart';
import 'package:famradar/models/location_model.dart';
import 'package:famradar/modules/webrtc/interfaces/signaling_service_interfacace.dart';
import 'package:famradar/modules/webrtc/models/ice_candidate_model.dart';
import 'package:famradar/providers/app_provider.dart';
import 'package:flutter/services.dart';
import '../interfaces/webrtc_service_interface.dart';

class WebRTCService implements WebRTCServiceInterface {
  static const _webrtcChannel = MethodChannel('avs.com.famradar/webrtc_events');
  final AppProvider _appProvider;
  final SignalingServiceInterface _signalingService;
  final PermissionServiceInterface _permissionService;

  WebRTCService({
    required AppProvider appProvider,
    required SignalingServiceInterface signalingService,
    required PermissionServiceInterface permissionService,
  }) : _appProvider = appProvider,
       _signalingService = signalingService,
       _permissionService = permissionService {
    _webrtcChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      if (call.method == 'onIceCandidate') {
        final args = call.arguments as Map?;
        if (args != null) {
          final candidate = IceCandidateModel.fromMap(
            args.cast<String, dynamic>(),
          );
          await _signalingService.sendIceCandidate(
            userId: candidate.userId,
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: candidate.sdpMLineIndex,
            sdp: candidate.sdp,
          );
          _appProvider.handleIceCandidate(candidate);
        } else {
          _appProvider.showError('Invalid ICE candidate arguments');
        }
      } else if (call.method == 'onLocationUpdate') {
        final args = call.arguments as Map?;
        if (args != null) {
          final location = LocationModel.fromMap(args.cast<String, dynamic>());
          _appProvider.updateUserLocation(location);
        } else {
          _appProvider.showError('Invalid location update arguments');
        }
      } else {
        _appProvider.showError('Unhandled WebRTC method: ${call.method}');
      }
    } catch (e) {
      _appProvider.showError('Error processing WebRTC event: $e');
    }
  }

  @override
  Future<void> startWebRTCConnection(String userId) async {
    try {
      if (await _permissionService.checkPermissions()) {
        await _signalingService.createOffer(userId);
      } else {
        _appProvider.showError('Location permissions required.');
        await _permissionService.openAppSettings();
      }
    } catch (e) {
      _appProvider.showError('Error starting WebRTC connection: $e');
    }
  }

  @override
  Future<void> addIceCandidate({
    required String userId,
    required String sdpMid,
    required int sdpMLineIndex,
    required String sdp,
  }) async {
    try {
      if (await _permissionService.checkPermissions()) {
        await _webrtcChannel.invokeMethod('addIceCandidate', {
          'userId': userId,
          'sdpMid': sdpMid,
          'sdpMLineIndex': sdpMLineIndex,
          'sdp': sdp,
        });
      } else {
        _appProvider.showError('Location permissions required.');
        await _permissionService.openAppSettings();
      }
    } catch (e) {
      _appProvider.showError('Error adding ICE candidate: $e');
    }
  }
}
