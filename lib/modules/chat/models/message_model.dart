// lib/modules/chat/models/message_model.dart
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final int timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp,
  };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
    id: map['id'] as String,
    senderId: map['senderId'] as String,
    text: map['text'] as String,
    timestamp: map['timestamp'] as int,
  );
}
