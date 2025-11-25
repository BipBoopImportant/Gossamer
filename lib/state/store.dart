import 'dart:async';
import 'dart:io' as io;
import 'dart:ffi' as ffi;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../bridge_generated.dart';
import '../services/mesh_controller.dart';

final api = NativeImpl(io.Platform.isIOS || io.Platform.isMacOS
    ? ffi.DynamicLibrary.executable()
    : ffi.DynamicLibrary.open('libnative.so'));

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  Timer? _syncTimer;

  ChatNotifier() : super([]) {
    // Auto-Initialize on creation
    initialize();
  }

  Future<void> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await api.initCore(appFilesDir: dir.path);
      
      // Initial Sync
      await sync();
      
      // Start Hardware Mesh
      await MeshController().init();
      
      // Start Auto-Sync Loop (Heartbeat)
      _startHeartbeat();
      
    } catch (e) {
      debugPrint("Core Init Error: $e");
    }
  }

  void _startHeartbeat() {
    _syncTimer?.cancel();
    // Poll every 5 seconds for new messages from Relay/Mesh
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await sync();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> sync() async {
    try {
      final msgs = await api.syncMessages();
      // Sort: Newest first
      msgs.sort((a, b) => b.time.compareTo(a.time));
      
      // Only update state if changed (simple check) to prevent redraws
      if (msgs.length != state.length) {
        state = msgs;
      } else if (msgs.isNotEmpty && state.isNotEmpty && msgs.first.id != state.first.id) {
        state = msgs;
      }
    } catch (e) {
      // Silent fail on network error (keep local state)
    }
  }

  Future<void> sendMessage(String dest, String text) async {
    try {
      // Optimistic UI Update
      final temp = ChatMessage(
        id: "temp_${DateTime.now().millisecondsSinceEpoch}", 
        sender: "Me", 
        text: text, 
        time: DateTime.now().millisecondsSinceEpoch ~/ 1000, 
        isMe: true
      );
      state = [temp, ...state];
      
      // 1. Network Send
      await api.sendMessage(destHex: dest, content: text);
      
      // 2. Mesh Broadcast
      await MeshController().broadcastMessage(dest, text);
      
      // 3. Confirm Sync
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
  return ChatNotifier();
});

final identityProvider = FutureProvider<String>((ref) async {
  // Ensure Core is ready before fetching Identity
  final dir = await getApplicationDocumentsDirectory();
  await api.initCore(appFilesDir: dir.path);
  return api.getMyIdentity();
});

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  // Ensure Core is ready
  final dir = await getApplicationDocumentsDirectory();
  await api.initCore(appFilesDir: dir.path);
  return api.getContacts();
});

final addContactProvider = Provider((ref) => (String key, String alias) async {
  await api.addContact(pubkey: key, alias: alias);
  ref.refresh(contactsProvider);
});
