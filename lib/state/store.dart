import 'dart:async';
import 'dart:io' as io;
import 'dart:ffi' as ffi;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bridge_generated.dart';

final api = NativeImpl(io.Platform.isIOS || io.Platform.isMacOS
    ? ffi.DynamicLibrary.executable()
    : ffi.DynamicLibrary.open('libnative.so'));

// --- Providers ---

// The stream of live events from Rust
final eventStreamProvider = StreamProvider<String>((ref) {
  return api.createEventStream();
});

// Provider for tracking who is typing
final typingStatusProvider = StateProvider<Map<String, bool>>((ref) => {});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  // ... [Existing code: initialize, sync, sendMessage] ...
  // No changes needed to the core ChatNotifier for this feature
}

// ... [Existing Providers: chatProvider, identityProvider, etc.] ...
// Unchanged from previous scripts for brevity
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) => ChatNotifier());
final identityProvider = FutureProvider<String>((ref) async { /* ... */ return ""; });
final contactsProvider = FutureProvider<List<Contact>>((ref) async { /* ... */ return []; });
final addContactProvider = Provider((ref) => (String k, String a) async {});
