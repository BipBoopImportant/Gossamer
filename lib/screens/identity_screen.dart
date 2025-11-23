import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter/services.dart';

class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  // Mock ID
  final String myId = "a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      appBar: AppBar(title: const Text("MY IDENTITY", style: TextStyle(letterSpacing: 2))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Holographic Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A24), Color(0xFF0F0F13)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.1), blurRadius: 30, spreadRadius: 0)
                ]
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(UniconsLine.circuit, color: Colors.white54),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("ROOT SECRET", style: TextStyle(color: Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: QrImageView(
                      data: myId,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Scan to add contact", style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Copy Action
            ListTile(
              onTap: () {
                Clipboard.setData(ClipboardData(text: myId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Identity copied to clipboard")));
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: const Color(0xFF15151F),
              leading: const Icon(UniconsLine.copy, color: Colors.white),
              title: const Text("Copy Hex String", style: TextStyle(color: Colors.white)),
              trailing: const Icon(UniconsLine.angle_right, color: Colors.white24),
            )
          ],
        ),
      ),
    );
  }
}
