import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  final String myId = "a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient from shell
      appBar: AppBar(title: const Text("MY IDENTITY")),
      body: SingleChildScrollView( // Prevent overflow on small screens
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Holographic Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A24), Color(0xFF0F0F13)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.15), blurRadius: 40, spreadRadius: 0)
                ]
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(UniconsLine.circuit, color: Colors.white54),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5))
                        ),
                        child: const Text("ROOT SECRET", style: TextStyle(color: Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  // QR Code with white padding
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: QrImageView(
                      data: myId,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(myId.substring(0, 16) + "...", style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', letterSpacing: 2)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Actions
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: UniconsLine.copy, 
                    label: "COPY", 
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: myId));
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Identity copied to clipboard")));
                    }
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionButton(
                    icon: UniconsLine.share_alt, 
                    label: "SHARE", 
                    onTap: () => Share.share("My Gossamer ID: $myId"),
                    isPrimary: true,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF6C63FF) : const Color(0xFF15151F),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
