// lib/modules/history/services/history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famradar/modules/history/interfaces/history-service_interface.dart';
import 'package:famradar/providers/app_provider.dart';
import '../models/location_history_model.dart';

class HistoryService implements HistoryServiceInterface {
  final AppProvider _appProvider;
  final FirebaseFirestore _firestore;

  HistoryService({
    required AppProvider appProvider,
    FirebaseFirestore? firestore,
  }) : _appProvider = appProvider,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveLocation(LocationHistoryModel location) async {
    try {
      await _firestore
          .collection('history')
          .doc(location.userId)
          .collection('locations')
          .doc(location.timestamp.toString())
          .set(location.toMap());
    } catch (e) {
      _appProvider.showError('Error saving location: $e');
    }
  }

  @override
  Stream<List<LocationHistoryModel>> getLocationHistory(String userId) {
    return _firestore
        .collection('history')
        .doc(userId)
        .collection('locations')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => LocationHistoryModel.fromMap(doc.data()))
                  .toList(),
        );
  }
}
