import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF15151F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text("CONFIGURATION", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          _buildTile(UniconsLine.key_skeleton, "Identity Backup", "Export root secret"),
          _buildTile(UniconsLine.database, "Storage", "12.4 MB Cached"),
          _buildTile(UniconsLine.server_network, "Relay", "wss://damus.io (Connected)"),
          _buildTile(UniconsLine.shield, "Encryption", "XChaCha20-Poly1305"),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(UniconsLine.power, color: Colors.red),
              label: const Text("DISCONNECT MESH", style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
              ],
            ),
          ),
          const Icon(UniconsLine.angle_right, color: Colors.white24),
        ],
      ),
    );
  }
}
