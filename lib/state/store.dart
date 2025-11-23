import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bridge_generated.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ffi';

final api = NativeImpl(Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.executable()
    : DynamicLibrary.open('libnative.so'));

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  Future<void> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await api.initCore(appFilesDir: dir.path);
      await sync();
    } catch (e) { debugPrint("Err: $e"); }
  }

  Future<void> sync() async {
    try {
      final msgs = await api.syncMessages();
      msgs.sort((a, b) => b.time.compareTo(a.time));
      state = msgs;
    } catch (e) { debugPrint("Sync Err: $e"); }
  }

  Future<void> sendMessage(String dest, String text) async {
    try {
      final temp = ChatMessage(id: "temp", sender: "Me", text: text, time: DateTime.now().millisecondsSinceEpoch ~/ 1000, isMe: true);
      state = [temp, ...state];
      await api.sendMessage(destHex: dest, content: text);
      await sync();
    } catch (e) { debugPrint("Send Err: $e"); }
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

// NEW: Contacts Provider
final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  // Trigger dependency on identity to ensure initCore is called
  ref.watch(identityProvider);
  return api.getContacts();
});

// Helper to add contact
final addContactProvider = Provider((ref) => (String key, String alias) async {
  await api.addContact(pubkey: key, alias: alias);
  ref.refresh(contactsProvider);
});
