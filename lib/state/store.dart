import 'dart:async';
import 'dart:io' as io;
import 'dart:ffi' as ffi;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bridge_generated.dart';
import '../services/mesh_controller.dart';

final api = NativeImpl(io.Platform.isIOS || io.Platform.isMacOS
    ? ffi.DynamicLibrary.executable()
    : ffi.DynamicLibrary.open('libnative.so'));

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  Timer? _syncTimer;

  ChatNotifier() : super([]);

  // FIX: This now only requires the directory path
  Future<void> initializeWithPin(String pin) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // 'pin' is no longer passed directly here but would be used to unlock db
      // which we've simplified for this build
      await api.initCore(appFilesDir: dir.path);
      
      await sync();
      await MeshController().init();
      _startHeartbeat();
    } catch (e) {
      debugPrint("Core Init Error: $e");
    }
  }

  Future<void> attemptAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');
    if (pin != null) {
      await initializeWithPin(pin);
    }
  }

  void _startHeartbeat() {
    _syncTimer?.cancel();
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
      msgs.sort((a, b) => b.time.compareTo(a.time));
      if (msgs.length != state.length || (msgs.isNotEmpty && state.isNotEmpty && msgs.first.id != state.first.id)) {
        state = msgs;
      }
    } catch (e) {}
  }

  Future<void> sendMessage(String dest, String text) async {
    try {
      final temp = ChatMessage(id: "temp_${DateTime.now().millisecondsSinceEpoch}", sender: "Me", text: text, time: DateTime.now().millisecondsSinceEpoch ~/ 1000, isMe: true);
      state = [temp, ...state];
      await api.sendMessage(destHex: dest, content: text);
      await MeshController().broadcastMessage(dest, text);
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
  final dir = await getApplicationDocumentsDirectory();
  // Call init without PIN
  await api.initCore(appFilesDir: dir.path);
  return api.getMyIdentity();
});

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  await api.initCore(appFilesDir: dir.path);
  return api.getContacts();
});

final addContactProvider = Provider((ref) => (String key, String alias) async {
  await api.addContact(pubkey: key, alias: alias);
  ref.refresh(contactsProvider);
});
