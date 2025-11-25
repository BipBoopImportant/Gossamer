import 'dart:async';
import 'dart:io' as io;
import 'dart:ffi' as ffi;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bridge_generated.dart';
import '../services/mesh_controller.dart';

// --- FFI Bridge Setup ---
final api = NativeImpl(io.Platform.isIOS || io.Platform.isMacOS
    ? ffi.DynamicLibrary.executable()
    : ffi.DynamicLibrary.open('libnative.so'));

// --- Providers ---

// FIX 1: Central Initialization Provider
// This runs ONCE and prepares the Rust core. All other providers will depend on it.
final coreReadyProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final pin = prefs.getString('user_pin');
  if (pin == null) {
    throw Exception("User not onboarded. PIN is missing.");
  }
  
  final dir = await getApplicationDocumentsDirectory();
  await api.initCore(appFilesDir: dir.path, pin: pin);
  
  // Initialize the mesh network after the core is ready
  await MeshController().init();
  
  return true; // Signal success
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  Timer? _syncTimer;

  ChatNotifier(this.ref) : super([]);

  // This is now called by the UI after core is ready.
  Future<void> start() async {
    // Wait for the core to be initialized.
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
      // Only update state if the data has actually changed
      if (!listEquals(msgs, state)) {
        state = msgs;
      }
    } catch (e) {
      // Fail silently on network errors
    }
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
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

// FIX 2: All data providers now DEPEND on coreReadyProvider.
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

// Provider for completing the onboarding process
final onboardingProvider = Provider((ref) => (String pin) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', true);
  await prefs.setString('user_pin', pin);
  // Invalidate the old providers so they re-run with the new PIN
  ref.invalidate(coreReadyProvider);
  ref.invalidate(identityProvider);
});
