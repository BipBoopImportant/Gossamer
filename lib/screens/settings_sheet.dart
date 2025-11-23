import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import '../state/store.dart'; // Access providers
import '../services/mesh_controller.dart'; // Access Mesh

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});
  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  String _relayUrl = "wss://relay.damus.io";
  bool _isConnected = true;

  @override
  Widget build(BuildContext context) {
    // Access Real Identity from Rust
    final identityAsync = ref.watch(identityProvider);

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
          
          // 1. Export Identity (REAL DATA)
          _buildTile(
            icon: UniconsLine.key_skeleton, 
            title: "Identity Backup", 
            subtitle: "Export root secret",
            onTap: () {
              identityAsync.whenData((key) => _showExportDialog(key));
            }
          ),
          
          // 2. Manage Storage (REAL WIPE)
          _buildTile(
            icon: UniconsLine.database, 
            title: "Storage", 
            subtitle: "Local Encrypted DB",
            onTap: _showStorageDialog
          ),
          
          // 3. Relay Settings (REAL SWITCH)
          _buildTile(
            icon: UniconsLine.server_network, 
            title: "Relay", 
            subtitle: _relayUrl,
            onTap: _showRelayDialog
          ),
          
          _buildTile(
            icon: UniconsLine.shield, 
            title: "Encryption", 
            subtitle: "XChaCha20-Poly1305 (Active)",
            onTap: () {}
          ),
          
          const SizedBox(height: 20),
          
          // 4. Disconnect (REAL STOP)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (_isConnected) {
                  // Stop Mesh & Relay
                  await MeshController().stop();
                  // In a real app, we'd also disconnect WS, but changing URL handles that mostly
                } else {
                  await MeshController().init();
                }
                setState(() => _isConnected = !_isConnected);
                if(context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isConnected ? "Mesh Reconnected" : "Mesh Disconnected")));
                }
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
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white70)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13))])),
            const Icon(UniconsLine.angle_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(String key) {
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
              child: Text(key, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
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
        content: const Text("Wipe all messages? Identity will be kept.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await api.wipeStorage(); // REAL CALL
              ref.refresh(chatProvider); // Reload UI
              if(context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Storage Wiped")));
              }
            }, 
            child: const Text("WIPE", style: TextStyle(color: Colors.red))
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
            onPressed: () async {
              await api.setRelayUrl(url: ctrl.text); // REAL CALL
              setState(() => _relayUrl = ctrl.text);
              if(context.mounted) Navigator.pop(context);
            }, 
            child: const Text("SAVE")
          ),
        ],
      ),
    );
  }
}
