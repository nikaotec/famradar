

import 'package:famradar/models/location_model.dart';

abstract class SignalingServiceInterface {
  Future<void> createOffer(String userId);
  Future<void> sendAnswer(String userId, String offerSdp);
  Future<void> sendIceCandidate({
    required String userId,
    required String sdpMid,
    required int sdpMLineIndex,
    required String sdp,
  });
  Future<void> sendLocationUpdate(String userId, LocationModel location);
}
