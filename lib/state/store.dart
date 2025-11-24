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

// 1. Core Initialization Provider (Singleton Future)
final coreInitProvider = FutureProvider<void>((ref) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    await api.initCore(appFilesDir: dir.path);
    await MeshController().init();
  } catch (e) {
    debugPrint("CRITICAL: Core Init Failed: $e");
    throw e; // Re-throw to show error state in UI
  }
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this.ref) : super([]);
  final Ref ref;

  Future<void> sync() async {
    try {
      // Ensure core is ready before syncing
      await ref.read(coreInitProvider.future);
      final msgs = await api.syncMessages();
      msgs.sort((a, b) => b.time.compareTo(a.time));
      state = msgs;
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  Future<void> sendMessage(String dest, String text) async {
    try {
      await ref.read(coreInitProvider.future);
      
      // Optimistic Update
      final temp = ChatMessage(
        id: "temp_${DateTime.now().millisecondsSinceEpoch}", 
        sender: "Me", 
        text: text, 
        time: DateTime.now().millisecondsSinceEpoch ~/ 1000, 
        isMe: true
      );
      state = [temp, ...state];

      api.sendMessage(destHex: dest, content: text).then((_) => sync());
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
  // Trigger init immediately
  ref.listen(coreInitProvider, (_, __) {});
  final notifier = ChatNotifier(ref);
  // Sync once core is ready
  ref.read(coreInitProvider.future).then((_) => notifier.sync());
  return notifier;
});

final identityProvider = FutureProvider<String>((ref) async {
  // FIX: Wait for Core Init BEFORE asking for identity
  await ref.watch(coreInitProvider.future);
  return api.getMyIdentity();
});

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  await ref.watch(coreInitProvider.future);
  return api.getContacts();
});

final addContactProvider = Provider((ref) => (String key, String alias) async {
  await api.addContact(pubkey: key, alias: alias);
  ref.refresh(contactsProvider);
});
