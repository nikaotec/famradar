// lib/modules/chat/interfaces/chat_service_interface.dart
import '../models/message_model.dart';

abstract class ChatServiceInterface {
  Stream<List<MessageModel>> getMessages(String familyId);
  Future<void> sendMessage(String familyId, MessageModel message);
}
