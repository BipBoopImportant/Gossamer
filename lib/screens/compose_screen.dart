import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import '../state/store.dart';
import 'qr_scan_screen.dart';
import 'nfc_screen.dart';
import 'contact_picker.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});
  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _destCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF050507),
        appBar: AppBar(title: const Text("NEW TRANSMISSION", style: TextStyle(letterSpacing: 2, fontSize: 14))),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TARGET IDENTITY", style: TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              TextField(
                controller: _destCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Paste Hex Key or Scan...",
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Contact Picker
                      IconButton(
                        icon: const Icon(UniconsLine.book_open, color: Color(0xFF6C63FF)),
                        onPressed: () async {
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (c) => const ContactPicker()
                          );
                          if (result != null) setState(() => _destCtrl.text = result);
                        },
                      ),
                      // QR Scan
                      IconButton(
                        icon: const Icon(UniconsLine.qrcode_scan, color: Colors.white54),
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const QrScanScreen()));
                          if (result != null) setState(() => _destCtrl.text = result);
                        },
                      ),
                      // NFC Scan
                      IconButton(
                        icon: const Icon(UniconsLine.wifi_router, color: Colors.white54),
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const NfcScreen(myIdentity: null)));
                          if (result != null) setState(() => _destCtrl.text = result);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("ENCRYPTED PAYLOAD", style: TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "Enter message content..."),
                ),
              ),
              const SizedBox(height: 24),
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_msgCtrl.text.isNotEmpty && _destCtrl.text.isNotEmpty) {
                        // Auto-save to contacts if it's new
                        ref.read(addContactProvider)(_destCtrl.text, "Unknown ${_destCtrl.text.substring(0,4)}");
                        
                        await ref.read(chatProvider.notifier).sendMessage(_destCtrl.text, _msgCtrl.text);
                        if(context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Queued for Uplink")));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(UniconsLine.rocket, color: Colors.white),
                    label: const Text("INITIATE UPLINK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
