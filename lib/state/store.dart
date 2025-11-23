import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bridge_generated.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ffi';

// Setup FFI
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
    } catch (e) {
      debugPrint("Init Error: $e");
    }
  }

  Future<void> sync() async {
    try {
      final msgs = await api.syncMessages();
      state = msgs;
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  Future<void> sendMessage(String dest, String text) async {
    try {
      await api.sendMessage(destHex: dest, content: text);
      await sync(); // Refresh list
    } catch (e) {
      debugPrint("Send Error: $e");
    }
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
