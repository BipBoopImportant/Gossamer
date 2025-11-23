import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import '../state/store.dart';

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
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: "Paste Hex Key",
                  suffixIcon: IconButton(icon: const Icon(UniconsLine.qrcode_scan), onPressed: (){}),
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
                  decoration: const InputDecoration(
                    hintText: "Enter message content...",
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_msgCtrl.text.isNotEmpty) {
                        ref.read(chatProvider.notifier).sendMessage(_msgCtrl.text);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Queued for Uplink")));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
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
