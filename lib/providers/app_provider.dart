// lib/providers/app_provider.dart
import 'package:famradar/modules/geofence/models.dart/geofence_model.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../modules/webrtc/models/ice_candidate_model.dart';
import '../modules/chat/models/message_model.dart';

class AppProvider with ChangeNotifier {
  UserModel? _currentUser;
  final Map<String, UserModel> _familyMembers = {};
  final Map<String, LocationModel> _userLocations = {};
  final Map<String, GeofenceModel> _geofences = {};
  final Map<String, List<MessageModel>> _messages = {};
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  Map<String, UserModel> get familyMembers => Map.unmodifiable(_familyMembers);
  Map<String, LocationModel> get userLocations =>
      Map.unmodifiable(_userLocations);
  Map<String, GeofenceModel> get geofences => Map.unmodifiable(_geofences);
  Map<String, List<MessageModel>> get messages => Map.unmodifiable(_messages);
  String? get errorMessage => _errorMessage;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    _familyMembers[user.id] = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _familyMembers.clear();
    notifyListeners();
  }

  void updateFamilyMember(UserModel member) {
    _familyMembers[member.id] = member;
    notifyListeners();
  }

  void updateUserLocation(LocationModel location) {
    _userLocations[location.userId] = location;
    notifyListeners();
  }

  void addGeofence(GeofenceModel geofence) {
    _geofences[geofence.id] = geofence;
    notifyListeners();
  }

  void handleGeofenceEvent({
    required String type,
    required String geofenceId,
    String? userId,
    required int timestamp,
  }) {
    _errorMessage =
        'Geofence $type: ID $geofenceId${userId != null ? ", User: $userId" : ""} at ${DateTime.fromMillisecondsSinceEpoch(timestamp)}';
    notifyListeners();
  }

    void handleInvitationEvent(Map<String, dynamic> event) {
    // Handle invitation events (e.g., sent, accepted, rejected)
    notifyListeners();
  }

  void handleIceCandidate(IceCandidateModel candidate) {
    notifyListeners();
  }

  void updateMessages(String familyId, List<MessageModel> messages) {
    _messages[familyId] = messages;
    notifyListeners();
  }

  void showError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
