import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/store.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String ghostId;
  const ChatScreen({super.key, required this.ghostId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Filter messages for this thread (Simple filtering by sender name/ID)
    // In a real app, we'd have thread IDs. Here we filter by 'isMe' or 'SenderName'
    final allMessages = ref.watch(chatProvider);
    final thread = allMessages.where((m) => m.sender == widget.ghostId || (m.isMe && widget.ghostId == "Ghost")).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF050507),
        appBar: AppBar(
          backgroundColor: const Color(0xFF15151F),
          leading: IconButton(icon: const Icon(UniconsLine.arrow_left), onPressed: () => Navigator.pop(context)),
          title: Text(widget.ghostId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true, // Build from bottom
                padding: const EdgeInsets.all(20),
                itemCount: thread.length,
                itemBuilder: (context, index) {
                  final msg = thread[index];
                  return Align(
                    alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: const BoxConstraints(maxWidth: 260),
                      decoration: BoxDecoration(
                        color: msg.isMe ? const Color(0xFF6C63FF) : const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(msg.text, style: const TextStyle(color: Colors.white)),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF15151F), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(hintText: "Secure Message...", fillColor: Colors.black, isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () {
                          if (_ctrl.text.isNotEmpty) {
                            // Send to this specific Ghost ID (Requires Hex in real usage)
                            // For this UI, we send to a dummy hex if ghostId isn't a hex
                            String dest = widget.ghostId.length == 64 ? widget.ghostId : "0000000000000000000000000000000000000000000000000000000000000000";
                            ref.read(chatProvider.notifier).sendMessage(dest, _ctrl.text);
                            _ctrl.clear();
                            HapticFeedback.lightImpact();
                          }
                        },
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                        icon: const Icon(UniconsLine.message, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
