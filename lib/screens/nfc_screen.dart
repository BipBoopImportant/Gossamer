import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:unicons/unicons.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:convert';

class NfcScreen extends StatefulWidget {
  final String? myIdentity;
  const NfcScreen({super.key, this.myIdentity});
  @override
  State<NfcScreen> createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> {
  String _status = "INITIALIZING NEURAL LINK...";
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _startNfc();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  void _startNfc() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() => _status = "NFC HARDWARE NOT DETECTED");
      return;
    }

    if (widget.myIdentity != null) {
      // BROADCAST
      setState(() => _status = "BROADCASTING IDENTITY...\nTAP DEVICE");
      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        try {
          NdefMessage message = NdefMessage([NdefRecord.createText(widget.myIdentity!)]);
          Ndef? ndef = Ndef.from(tag);
          if (ndef != null && ndef.isWritable) {
            await ndef.write(message);
            _handleSuccess(null, "IDENTITY TRANSMITTED");
          }
        } catch (e) { /* Ignore */ }
      });
    } else {
      // RECEIVE (Scan)
      setState(() => _status = "SCANNING FOR CONTACT...\nTAP DEVICE");
      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        Ndef? ndef = Ndef.from(tag);
        if (ndef?.cachedMessage != null) {
          for (var record in ndef!.cachedMessage!.records) {
             try {
               String payload = utf8.decode(record.payload).substring(3);
               if (payload.length > 10) _handleSuccess(payload, "CONTACT ACQUIRED");
             } catch (e) { /* Ignore */ }
          }
        }
      });
    }
  }

  void _handleSuccess(String? payload, String msg) {
    NfcManager.instance.stopSession();
    if (mounted) {
      setState(() { _success = true; _status = msg; });
      // FIX: Return the payload when popping
      Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context, payload));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBroadcast = widget.myIdentity != null;
    final color = isBroadcast ? const Color(0xFF6C63FF) : const Color(0xFF00F0FF);
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      body: Stack(
        children: [
          Center(child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.2), width: 2))).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds)),
          Center(child: _success ? const Icon(UniconsLine.check_circle, color: Colors.white, size: 80).animate().scale() : Icon(UniconsLine.wifi_router, color: Colors.white, size: 80).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 500.ms).fadeOut(delay: 500.ms)),
          Positioned(bottom: 150, left: 20, right: 20, child: Column(children: [Text(isBroadcast ? "TRANSMITTING" : "RECEIVING", style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 18)), const SizedBox(height: 20), Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontFamily: 'monospace'))])),
          Positioned(top: 60, right: 20, child: IconButton.filled(onPressed: () => Navigator.pop(context), style: IconButton.styleFrom(backgroundColor: Colors.white10), icon: const Icon(UniconsLine.multiply, color: Colors.white))),
        ],
      ),
    );
  }
}
