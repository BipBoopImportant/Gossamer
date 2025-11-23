import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../state/store.dart';
import 'nfc_screen.dart';

class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("MY IDENTITY")),
      body: identityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
        data: (myId) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Holographic Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A1A24), Color(0xFF0F0F13)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.15), blurRadius: 40, spreadRadius: 0)]
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(UniconsLine.circuit, color: Colors.white54),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5))),
                          child: const Text("ROOT SECRET", style: TextStyle(color: Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(data: myId, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(myId.substring(0, 16) + "...", style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', letterSpacing: 2)),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: myId));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Identity Copied")));
                      },
                      child: Container(height: 60, decoration: BoxDecoration(color: const Color(0xFF15151F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)), child: const Center(child: Icon(UniconsLine.copy, color: Colors.white))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => Share.share(myId),
                      child: Container(height: 60, decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(16)), child: const Center(child: Icon(UniconsLine.share_alt, color: Colors.white))),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
