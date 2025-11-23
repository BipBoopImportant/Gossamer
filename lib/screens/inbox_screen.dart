import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("ENCRYPTED INBOX", style: TextStyle(letterSpacing: 2))),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
        itemCount: 4,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(ghostId: "Ghost-${index + 884}")));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A24).withOpacity(0.9), // Less opaque for readability
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 90,
                    decoration: BoxDecoration(
                      color: index == 0 ? const Color(0xFF00F0FF) : Colors.transparent,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[900],
                    child: const Icon(UniconsLine.lock, color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ghost ID ${index + 884}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          index == 0 ? "New coordinates received..." : "Decrypted payload.", 
                          style: TextStyle(color: index == 0 ? Colors.white : Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text("2m", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
