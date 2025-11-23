import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class ChatScreen extends StatelessWidget {
  final String ghostId;
  const ChatScreen({super.key, required this.ghostId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15151F),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SECURE CHANNEL", style: TextStyle(fontSize: 10, color: Color(0xFF00F0FF), letterSpacing: 2)),
            Text(ghostId, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(UniconsLine.trash_alt, color: Colors.redAccent), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildBubble("Connection established via Relay 4.", isSystem: true),
                _buildBubble("Handshake successful. Identity verified.", isSystem: true),
                _buildBubble("Are we secure?", isMe: false),
                _buildBubble("Yes. XChaCha20-Poly1305 active.", isMe: true),
                _buildBubble("Sending coordinates now.", isMe: false),
              ],
            ),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, {bool isMe = false, bool isSystem = false}) {
    if (isSystem) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, letterSpacing: 1)),
        ),
      );
    }
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6C63FF).withOpacity(0.2) : const Color(0xFF1A1A24),
          border: Border.all(color: isMe ? const Color(0xFF6C63FF) : Colors.white10),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF15151F),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Encrypt message...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF6C63FF),
            child: IconButton(
              icon: const Icon(UniconsLine.message, color: Colors.white),
              onPressed: () {},
            ),
          )
        ],
      ),
    );
  }
}
