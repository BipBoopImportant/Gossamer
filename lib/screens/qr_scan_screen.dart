import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:unicons/unicons.dart';
class QrScanScreen extends StatefulWidget { const QrScanScreen({super.key}); @override State<QrScanScreen> createState() => _QrState(); }
class _QrState extends State<QrScanScreen> {
  bool _scanned = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: Stack(children: [
      MobileScanner(onDetect: (capture) { if (_scanned) return; for (final b in capture.barcodes) { if (b.rawValue != null) { _scanned = true; Navigator.pop(context, b.rawValue); break; } } }),
      Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5), width: 50))),
      Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: const Color(0xFF6C63FF), width: 2), borderRadius: BorderRadius.circular(20)))),
      Positioned(bottom: 50, left: 0, right: 0, child: Center(child: IconButton.filled(onPressed: () => Navigator.pop(context), style: IconButton.styleFrom(backgroundColor: Colors.white24), icon: const Icon(UniconsLine.multiply, color: Colors.white))))
    ]));
  }
}
