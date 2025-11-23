import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicons/unicons.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  String _relayUrl = "wss://relay.damus.io";
  bool _isConnected = true;

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
          
          // 1. Export Identity
          _buildTile(
            icon: UniconsLine.key_skeleton, 
            title: "Identity Backup", 
            subtitle: "Export root secret",
            onTap: _showExportDialog
          ),
          
          // 2. Manage Storage
          _buildTile(
            icon: UniconsLine.database, 
            title: "Storage", 
            subtitle: "12.4 MB Cached",
            onTap: _showStorageDialog
          ),
          
          // 3. Relay Settings
          _buildTile(
            icon: UniconsLine.server_network, 
            title: "Relay", 
            subtitle: _isConnected ? _relayUrl : "Disconnected",
            onTap: _showRelayDialog
          ),
          
          // 4. Encryption Info (Static)
          _buildTile(
            icon: UniconsLine.shield, 
            title: "Encryption", 
            subtitle: "XChaCha20-Poly1305 (Active)",
            onTap: () {}
          ),
          
          const SizedBox(height: 20),
          
          // 5. Disconnect Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _isConnected = !_isConnected);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isConnected ? "Mesh Reconnected" : "Mesh Disconnected")));
              },
              icon: Icon(UniconsLine.power, color: _isConnected ? Colors.red : Colors.green),
              label: Text(_isConnected ? "DISCONNECT MESH" : "CONNECT MESH", style: TextStyle(color: _isConnected ? Colors.red : Colors.green)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: _isConnected ? Colors.red : Colors.green), padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
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
      ),
    );
  }

  // --- DIALOGS ---

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text("ROOT SECRET", style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("WARNING: Anyone with this key can impersonate you.", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
              child: const Text("a1b2c3d4e5f67890...", style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: "a1b2c3d4e5f67890..."));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Secret copied to clipboard")));
            }, 
            child: const Text("COPY")
          ),
        ],
      ),
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text("MANAGE STORAGE", style: TextStyle(color: Colors.white)),
        content: const Text("Clear local message cache? Keys will be preserved.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Storage Cleared (12.4 MB freed)")));
            }, 
            child: const Text("CLEAR", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showRelayDialog() {
    final ctrl = TextEditingController(text: _relayUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text("RELAY SERVER", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "WebSocket URL", labelStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              setState(() => _relayUrl = ctrl.text);
              Navigator.pop(context);
            }, 
            child: const Text("SAVE")
          ),
        ],
      ),
    );
  }
}
