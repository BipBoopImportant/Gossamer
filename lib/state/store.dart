import 'dart:io' as io;
import 'dart:ffi' as ffi;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../bridge_generated.dart';
import '../services/mesh_controller.dart'; // Import Controller

final api = NativeImpl(io.Platform.isIOS || io.Platform.isMacOS
    ? ffi.DynamicLibrary.executable()
    : ffi.DynamicLibrary.open('libnative.so'));

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  Future<void> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await api.initCore(appFilesDir: dir.path);
      await sync();
      
      // START MESH
      await MeshController().init();
      
    } catch (e) {
      debugPrint("Init Error: $e");
    }
  }

  Future<void> sync() async {
    try {
      final msgs = await api.syncMessages();
      msgs.sort((a, b) => b.time.compareTo(a.time));
      state = msgs;
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  Future<void> sendMessage(String dest, String text) async {
    try {
      // 1. Send via Internet Relay
      await api.sendMessage(destHex: dest, content: text);
      
      // 2. Send via Bluetooth Mesh
      await MeshController().broadcastMessage(dest, text);
      
      // 3. Update UI
      await sync();
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
