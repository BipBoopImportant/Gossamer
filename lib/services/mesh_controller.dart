import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../state/store.dart';

class MeshController {
  static final MeshController _instance = MeshController._internal();
  factory MeshController() => _instance;
  MeshController._internal();

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  bool _isScanning = false;
  Timer? _rotationTimer;

  Future<void> init() async {
    if (await Permission.bluetooth.request().isDenied) return;
    if (await Permission.bluetoothScan.request().isDenied) return;
    if (await Permission.bluetoothAdvertise.request().isDenied) return;
    if (await Permission.bluetoothConnect.request().isDenied) return;
    if (await Permission.location.request().isDenied) return;

    await _peripheral.initialize();
    startScanning();
    _startPacketRotation();
  }

  void startScanning() {
    if (_isScanning) return;
    _isScanning = true;

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.advertisementData.manufacturerData.containsKey(0xFFFF)) {
          final data = r.advertisementData.manufacturerData[0xFFFF];
          if (data != null && data.isNotEmpty) {
            // Rust determines if it's for us OR saves it to transit
            api.ingestMeshPacket(data: Uint8List.fromList(data));
          }
        }
      }
    });

    FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
      allowDuplicates: true,
    );
  }

  // NEW: Multi-Hop Loop
  // Every 20 seconds, ask Rust for a transit packet and broadcast it.
  void _startPacketRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      try {
        // Ask Rust for a packet from the "Transit" pool
        final packet = await api.getTransitPacket();
        
        if (packet.isNotEmpty) {
          debugPrint("Mesh: Relaying transit packet (${packet.length} bytes)");
          await _peripheral.stop(); // Stop current ad
          
          final AdvertiseData data = AdvertiseData(
            manufacturerId: 0xFFFF,
            manufacturerData: packet,
            includeDeviceName: false,
          );
          await _peripheral.start(advertiseData: data);
        }
      } catch (e) {
        debugPrint("Rotation Error: $e");
      }
    });
  }

  Future<void> broadcastMessage(String destHex, String content) async {
    try {
      // Immediate Priority Broadcast
      final packet = await api.prepareMeshPacket(destHex: destHex, content: content);
      if (packet.length > 24) debugPrint("Packet size warning");

      await _peripheral.stop();
      final AdvertiseData data = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: packet,
        includeDeviceName: false,
      );
      await _peripheral.start(advertiseData: data);
      
      // Let it run for 15s before rotation takes over
    } catch (e) {
      debugPrint("Broadcast Error: $e");
    }
  }
}
