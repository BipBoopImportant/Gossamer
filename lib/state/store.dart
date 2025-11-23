import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple Message Model
class Message {
  final String id;
  final String sender;
  final String text;
  final DateTime time;
  final bool isMe;

  Message(this.id, this.sender, this.text, this.time, this.isMe);
}

// State Notifier to handle the list of messages
class ChatNotifier extends StateNotifier<List<Message>> {
  ChatNotifier() : super([
    Message("1", "Ghost-884", "Handshake established.", DateTime.now().subtract(const Duration(minutes: 5)), false),
    Message("2", "Ghost-884", "Identity verified via Relay.", DateTime.now().subtract(const Duration(minutes: 4)), false),
  ]);

  void sendMessage(String text) {
    state = [
      ...state,
      Message(DateTime.now().toString(), "Me", text, DateTime.now(), true)
    ];
  }
  
  void deleteMessage(String id) {
    state = [
      for (final msg in state)
        if (msg.id != id) msg,
    ];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<Message>>((ref) {
  return ChatNotifier();
});
