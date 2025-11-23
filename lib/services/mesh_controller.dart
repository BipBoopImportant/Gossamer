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
    // 1. Request Permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((s) => s.isDenied)) {
      debugPrint("Mesh Permissions Denied");
      return;
    }

    // 2. Start Scanning
    startScanning();
  }

  void startScanning() {
    if (_isScanning) return;
    _isScanning = true;

    // Listen for advertisements
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // 0xFFFF is a reserved testing ID, we use it for simplicity in this mesh
        if (r.advertisementData.manufacturerData.containsKey(0xFFFF)) {
          final data = r.advertisementData.manufacturerData[0xFFFF];
          if (data != null && data.isNotEmpty) {
            // Pass to Rust Core
            api.ingestMeshPacket(data: Uint8List.fromList(data));
          }
        }
      }
    });

    FlutterBluePlus.startScan(
      withServices: [], // Scan all
      allowDuplicates: true, // Need continuous updates
    );
  }

  // Broadcast a message to nearby devices
  Future<void> broadcastMessage(String destHex, String content) async {
    try {
      // 1. Get Encrypted Bytes from Rust
      final packet = await api.prepareMeshPacket(destHex: destHex, content: content);
      
      // 2. Advertise
      final AdvertiseData data = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: packet,
      );
      
      await _peripheral.start(advertiseData: data);
      
      // Stop after 30 seconds to save battery
      Future.delayed(const Duration(seconds: 30), () => _peripheral.stop());
      
    } catch (e) {
      debugPrint("Broadcast Error: $e");
    }
  }
}
