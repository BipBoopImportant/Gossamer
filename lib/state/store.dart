import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bridge_generated.dart';
import 'package:flutter/foundation.dart';
import '../main.dart'; // For global FFI access if needed

// We assume a global 'api' variable is available or we create one.
// For simplicity in this script, we define the singleton here.
final api = NativeImpl(io.Platform.isIOS || io.Platform.isMacOS
    ? io.DynamicLibrary.executable()
    : io.DynamicLibrary.open('libnative.so'));

import 'dart:io' as io;
import 'dart:ffi' as ffi;

class Message {
  final String id;
  final String sender;
  final String text;
  final DateTime time;
  final bool isMe;
  Message(this.id, this.sender, this.text, this.time, this.isMe);
}

class ChatNotifier extends StateNotifier<List<Message>> {
  ChatNotifier() : super([]);

  Future<void> initialize() async {
    try {
      await api.initCore();
      // Load some initial dummy data + check inbox
      final msgs = await api.checkInboxMock();
      for (var m in msgs) {
        state = [...state, Message(DateTime.now().toString(), "System", m, DateTime.now(), false)];
      }
    } catch (e) {
      debugPrint("Core Init Failed: $e");
    }
  }

  Future<void> sendMessage(String text) async {
    // Optimistic UI Update
    final tempId = DateTime.now().toString();
    state = [...state, Message(tempId, "Me", text, DateTime.now(), true)];
    
    try {
      // Call Rust (Simulated Network)
      // Using a dummy key for demo
      await api.sendMessageMock(destHex: "0000000000000000000000000000000000000000000000000000000000000000", msg: text);
    } catch (e) {
      // Error handling (could mark message as failed)
    }
  }
  
  void deleteMessage(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<Message>>((ref) {
  final notifier = ChatNotifier();
  notifier.initialize(); // Auto-init
  return notifier;
});

// Provider for Identity
final identityProvider = FutureProvider<String>((ref) async {
  await api.initCore(); // Ensure core is ready
  return api.getIdentity();
});
