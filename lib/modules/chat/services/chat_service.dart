// lib/modules/chat/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famradar/providers/app_provider.dart';
import '../interfaces/chat_service_interface.dart';
import '../models/message_model.dart';

class ChatService implements ChatServiceInterface {
  final AppProvider _appProvider;
  final FirebaseFirestore _firestore;

  ChatService({required AppProvider appProvider, FirebaseFirestore? firestore})
    : _appProvider = appProvider,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<MessageModel>> getMessages(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MessageModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  @override
  Future<void> sendMessage(String familyId, MessageModel message) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
    } catch (e) {
      _appProvider.showError('Error sending message: $e');
    }
  }
}
