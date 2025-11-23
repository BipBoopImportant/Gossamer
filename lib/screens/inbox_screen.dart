import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import 'package:intl/intl.dart';
import '../state/store.dart';
import 'chat_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);
    
    // Group by sender (Simple logic: just show unique threads or latest message)
    // For this UI demo, we treat every message in the store as a thread preview.
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("ENCRYPTED INBOX", style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: messages.isEmpty 
        ? Center(child: Text("No Signals Detected", style: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 1)))
        : ListView.builder(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 120),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Dismissible(
                key: Key(msg.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => ref.read(chatProvider.notifier).deleteMessage(msg.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                  child: const Icon(UniconsLine.trash_alt, color: Colors.red),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(ghostId: msg.sender))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: "avatar_${msg.sender}",
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF15151F),
                            child: const Icon(UniconsLine.lock, color: Color(0xFF6C63FF), size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(msg.sender, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                  Text(
                                    DateFormat('HH:mm').format(msg.time), 
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12)
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.text, 
                                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
