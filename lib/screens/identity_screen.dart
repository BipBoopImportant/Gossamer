import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'nfc_screen.dart';

class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});
  final String myId = "a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("MY IDENTITY")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A1A24), Color(0xFF0F0F13)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Text("ROOT SECRET", style: TextStyle(color: Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: QrImageView(data: myId, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => NfcScreen(myIdentity: myId))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15151F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF6C63FF))),
                ),
                icon: const Icon(UniconsLine.wifi_router, color: Color(0xFF6C63FF)),
                label: const Text("TAP TO SHARE (NFC)", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
