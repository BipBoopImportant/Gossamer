import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends StatefulWidget {
  final String ghostId;
  const ChatScreen({super.key, required this.ghostId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final List<String> _localMsgs = ["Secure Connection Established.", "Handshake Verified.", "Beginning Transfer..."];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
      child: Scaffold(
        backgroundColor: const Color(0xFF050507),
        appBar: AppBar(
          backgroundColor: const Color(0xFF15151F),
          leading: IconButton(
            icon: const Icon(UniconsLine.arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Hero(
                tag: "avatar_${widget.ghostId}",
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF050507),
                  child: Icon(UniconsLine.lock, size: 14, color: Color(0xFF6C63FF)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ENCRYPTED TUNNEL", style: TextStyle(fontSize: 10, color: Color(0xFF00F0FF), letterSpacing: 1)),
                  Text(widget.ghostId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _localMsgs.length,
                itemBuilder: (context, index) {
                  final isMe = index % 2 != 0;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: const BoxConstraints(maxWidth: 260),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF6C63FF) : const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                        ),
                      ),
                      child: Text(_localMsgs[index], style: const TextStyle(color: Colors.white)),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
                },
              ),
            ),
            
            // Input Area with SafeArea to avoid Home Bar overlap
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF15151F),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: SafeArea( // FIX: Respect bottom gesture bar
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Type secure message...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            fillColor: Colors.black,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            isDense: true, // Compact
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () {
                          if (_ctrl.text.isNotEmpty) {
                            setState(() => _localMsgs.add(_ctrl.text));
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
