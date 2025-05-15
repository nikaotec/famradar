// lib/modules/webrtc/interfaces/webrtc_service_interface.dart
abstract class WebRTCServiceInterface {
  Future<void> startWebRTCConnection(String userId);
  Future<void> addIceCandidate({
    required String userId,
    required String sdpMid,
    required int sdpMLineIndex,
    required String sdp,
  });
}
