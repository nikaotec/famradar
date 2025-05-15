// lib/modules/webrtc/models/ice_candidate_model.dart
class IceCandidateModel {
  final String userId;
  final String sdpMid;
  final int sdpMLineIndex;
  final String sdp;

  IceCandidateModel({
    required this.userId,
    required this.sdpMid,
    required this.sdpMLineIndex,
    required this.sdp,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'sdpMid': sdpMid,
    'sdpMLineIndex': sdpMLineIndex,
    'sdp': sdp,
  };

  factory IceCandidateModel.fromMap(Map<String, dynamic> map) =>
      IceCandidateModel(
        userId: map['userId'] as String,
        sdpMid: map['sdpMid'] as String,
        sdpMLineIndex: map['sdpMLineIndex'] as int,
        sdp: map['sdp'] as String,
      );
}
