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

  Future<void> init() async {
    if (await Permission.bluetooth.request().isDenied) return;
    if (await Permission.bluetoothScan.request().isDenied) return;
    if (await Permission.bluetoothAdvertise.request().isDenied) return;
    if (await Permission.bluetoothConnect.request().isDenied) return;
    if (await Permission.location.request().isDenied) return;

    // Configure Peripheral (Advertising)
    // We use a specific UUID for filtering, but the payload is in Manufacturer Data
    await _peripheral.initialize();
    
    startScanning();
  }

  void startScanning() {
    if (_isScanning) return;
    _isScanning = true;

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // 0xFFFF is our testing Manufacturer ID
        if (r.advertisementData.manufacturerData.containsKey(0xFFFF)) {
          final data = r.advertisementData.manufacturerData[0xFFFF];
          if (data != null && data.isNotEmpty) {
            // Feed binary data to Rust
            // Rust will determine if the packet is for us based on the compact header
            api.ingestMeshPacket(data: Uint8List.fromList(data));
          }
        }
      }
    });

    FlutterBluePlus.startScan(
      // LowLatency is crucial for mesh networking to catch brief advertisements
      androidScanMode: AndroidScanMode.lowLatency, 
      allowDuplicates: true,
    );
  }

  Future<void> broadcastMessage(String destHex, String content) async {
    try {
      final packet = await api.prepareMeshPacket(destHex: destHex, content: content);
      
      // SAFETY CHECK: BLE Packets are tiny (~27 bytes max usually)
      // If packet is too big, it won't broadcast.
      // For this MVP, we assume short messages ("Hi", "Here").
      if (packet.length > 24) {
        debugPrint("Warning: Packet size ${packet.length} exceeds BLE legacy limit. Might fail on some devices.");
      }

      final AdvertiseData data = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: packet,
        includeDeviceName: false,
      );
      
      // Cycle advertising to ensure it's picked up
      await _peripheral.start(advertiseData: data);
      await Future.delayed(const Duration(seconds: 10));
      await _peripheral.stop();
      
    } catch (e) {
      debugPrint("Broadcast Error: $e");
    }
  }
}
