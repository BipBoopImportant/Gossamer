import 'dart:async';
import 'dart:typed_data';
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
    // 1. Request Permissions
    if (await Permission.bluetooth.request().isDenied) return;
    if (await Permission.bluetoothScan.request().isDenied) return;
    if (await Permission.bluetoothAdvertise.request().isDenied) return;
    if (await Permission.bluetoothConnect.request().isDenied) return;
    if (await Permission.location.request().isDenied) return;

    // FIX: .initialize() removed in newer versions of flutter_ble_peripheral
    // It is now implicit or not required. We skip it.
    
    startScanning();
    _startPacketRotation();
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
            api.ingestMeshPacket(data: Uint8List.fromList(data));
          }
        }
      }
    });

    // FIX: API change in flutter_blue_plus 1.30+
    // allowDuplicates is replaced by continuousUpdates (implicit) or specific settings.
    // We use lowLatency to encourage frequent updates.
    FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
      // allowDuplicates: true, // REMOVED in new API
    );
  }

  void _startPacketRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      try {
        final packet = await api.getTransitPacket();
        
        if (packet.isNotEmpty) {
          debugPrint("Mesh: Relaying transit packet (${packet.length} bytes)");
          await _peripheral.stop(); 
          
          // FIX: Updated AdvertiseData API
          final AdvertiseData data = AdvertiseData(
            manufacturerId: 0xFFFF,
            manufacturerData: Uint8List.fromList(packet),
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
      final packet = await api.prepareMeshPacket(destHex: destHex, content: content);
      
      await _peripheral.stop();
      
      // FIX: Updated AdvertiseData API
      final AdvertiseData data = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: Uint8List.fromList(packet),
        includeDeviceName: false,
      );
      
      await _peripheral.start(advertiseData: data);
      
      // Keep broadcasting for 15s (High priority)
      await Future.delayed(const Duration(seconds: 15));
      
      // Stop (Rotation loop will take over later)
      await _peripheral.stop();
      
    } catch (e) {
      debugPrint("Broadcast Error: $e");
    }
  }
}
