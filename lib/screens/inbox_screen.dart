import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import 'package:intl/intl.dart';
import '../state/store.dart';
import 'chat_screen.dart';
import 'nfc_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("ENCRYPTED INBOX"),
        actions: [
          IconButton(
            icon: const Icon(UniconsLine.user_plus, color: Color(0xFF00F0FF)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NfcScreen(myIdentity: null))),
          )
        ],
      ),
      body: messages.isEmpty ? _buildEmptyState() : _buildList(context, ref, messages),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List messages) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 120),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(ghostId: msg.sender))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1A1A24).withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, backgroundColor: Color(0xFF15151F), child: Icon(UniconsLine.lock, color: Color(0xFF6C63FF), size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.sender, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Text(msg.text, style: TextStyle(color: Colors.grey[400], fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(UniconsLine.wind, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text("NO SIGNALS", style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 2, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
