// lib/modules/chat/screens/chat_screen.dart
import 'package:famradar/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../interfaces/chat_service_interface.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final ChatServiceInterface chatService;
  final String familyId;

  const ChatScreen({
    super.key,
    required this.chatService,
    required this.familyId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Family Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: widget.chatService.getMessages(widget.familyId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message.text),
                      subtitle: Text('From: ${message.senderId}'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_messageController.text.isNotEmpty) {
                      final message = MessageModel(
                        id: const Uuid().v4(),
                        senderId: userId,
                        text: _messageController.text,
                        timestamp: DateTime.now().millisecondsSinceEpoch,
                      );
                      await widget.chatService.sendMessage(
                        widget.familyId,
                        message,
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
