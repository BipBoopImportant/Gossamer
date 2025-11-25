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

// --- NEW: Add Status to ChatMessage ---
// Note: This is a Dart-side extension, the Rust struct remains the same.
// We will manage the status purely in the UI.
enum MessageStatus { sending, sent, failed }

// We create a wrapper class for UI state
class UIMessage {
  final ChatMessage core;
  final MessageStatus status;
  UIMessage(this.core, {this.status = MessageStatus.sent});
}

class ChatNotifier extends StateNotifier<List<UIMessage>> {
  final Ref ref;
  Timer? _syncTimer;

  ChatNotifier(this.ref) : super([]);

  Future<void> start() async {
    await ref.read(coreReadyProvider.future);
    _startHeartbeat();
    await sync();
  }

  void _startHeartbeat() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => sync());
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
      // Map to UI model
      final uiMsgs = msgs.map((m) => UIMessage(m, status: MessageStatus.sent)).toList();
      if (!listEquals(uiMsgs.map((m) => m.core.id).toList(), state.map((m) => m.core.id).toList())) {
        state = uiMsgs;
      }
    } catch (e) {}
  }

  Future<void> sendMessage(String dest, String text) async {
    final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    
    // 1. Optimistic Update with 'sending' status
    final tempCore = ChatMessage(id: tempId, sender: "Me", text: text, time: DateTime.now().millisecondsSinceEpoch ~/ 1000, isMe: true);
    final tempUi = UIMessage(tempCore, status: MessageStatus.sending);
    state = [tempUi, ...state];

    try {
      // 2. Await the real send
      await api.sendMessage(destHex: dest, content: text);
      await MeshController().broadcastMessage(dest, text);
      
      // 3. Update status to 'sent' after successful sync
      await sync(); // This will replace the temp message with the real one from DB

    } catch (e) {
      debugPrint("Send Error: $e");
      // 4. Update status to 'failed' on error
      state = [
        for (final msg in state)
          if (msg.core.id == tempId) UIMessage(msg.core, status: MessageStatus.failed) else msg,
      ];
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<UIMessage>>((ref) {
  return ChatNotifier(ref);
});

// --- Other providers remain unchanged ---
final coreReadyProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final pin = prefs.getString('user_pin');
  if (pin == null) throw Exception("User not onboarded");
  final dir = await getApplicationDocumentsDirectory();
  await api.initCore(appFilesDir: dir.path, pin: pin);
  await MeshController().init();
  return true;
});

final identityProvider = FutureProvider<String>((ref) async {
  await ref.watch(coreReadyProvider.future);
  return api.getMyIdentity();
});

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  await ref.watch(coreReadyProvider.future);
  return api.getContacts();
});

final addContactProvider = Provider((ref) => (String key, String alias) async {
  await api.addContact(pubkey: key, alias: alias);
  ref.refresh(contactsProvider);
});

final onboardingProvider = Provider((ref) => (String pin) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', true);
  await prefs.setString('user_pin', pin);
  ref.invalidate(coreReadyProvider);
  ref.invalidate(identityProvider);
});
