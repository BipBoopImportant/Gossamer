import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bridge_generated.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ffi';
import '../services/mesh_controller.dart';

final api = NativeImpl(Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.executable()
    : DynamicLibrary.open('libnative.so'));

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  Future<void> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await api.initCore(appFilesDir: dir.path);
      // Init Mesh Controller
      await MeshController().init();
      await sync();
    } catch (e) {
      debugPrint("Init Error: $e");
    }
  }

  Future<void> sync() async {
    try {
      final msgs = await api.syncMessages();
      // Sort Descending (Newest First)
      msgs.sort((a, b) => b.time.compareTo(a.time));
      state = msgs;
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  Future<void> sendMessage(String dest, String text) async {
    try {
      // 1. Optimistic Update (Show it immediately)
      final temp = ChatMessage(
        id: "temp_${DateTime.now().millisecondsSinceEpoch}", 
        sender: "Me", 
        text: text, 
        time: DateTime.now().millisecondsSinceEpoch ~/ 1000, 
        isMe: true
      );
      state = [temp, ...state];

      // 2. Send to Network (Background)
      // We intentionally don't await these fully to keep UI snappy
      api.sendMessage(destHex: dest, content: text).then((_) => sync());
      
      // 3. Send to Mesh
      MeshController().broadcastMessage(dest, text);
      
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }
  
  void deleteMessage(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final notifier = ChatNotifier();
  notifier.initialize();
  return notifier;
});

final identityProvider = FutureProvider<String>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  await api.initCore(appFilesDir: dir.path);
  return api.getMyIdentity();
});

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  ref.watch(identityProvider);
  return api.getContacts();
});

final addContactProvider = Provider((ref) => (String key, String alias) async {
  await api.addContact(pubkey: key, alias: alias);
  ref.refresh(contactsProvider);
});
