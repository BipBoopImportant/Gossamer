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
    if (await Permission.bluetooth.request().isDenied) return;
    if (await Permission.bluetoothScan.request().isDenied) return;
    if (await Permission.bluetoothAdvertise.request().isDenied) return;
    if (await Permission.bluetoothConnect.request().isDenied) return;
    if (await Permission.location.request().isDenied) return;

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
            api.ingestMeshPacket(data: Uint8List.fromList(data));
          }
        }
      }
    });

    FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
    );
  }

  void _startPacketRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      try {
        final packet = await api.getTransitPacket();
        
        if (packet.isNotEmpty) {
          await _peripheral.stop(); 
          
          // FIX: Use updated constructor format
          // In 0.4.x, AdvertiseData often relies on raw bytes or specific named args
          final AdvertiseData data = AdvertiseData(
            manufacturerId: 0xFFFF,
            manufacturerData: Uint8List.fromList(packet),
            includeDeviceName: false,
          );
          await _peripheral.start(advertiseData: data);
        }
      } catch (e) {
        // If constructor fails, we log it but don't crash app
        debugPrint("Rotation Error: $e");
      }
    });
  }

  Future<void> broadcastMessage(String destHex, String content) async {
    try {
      final packet = await api.prepareMeshPacket(destHex: destHex, content: content);
      
      await _peripheral.stop();
      
      final AdvertiseData data = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: Uint8List.fromList(packet),
        includeDeviceName: false,
      );
      
      await _peripheral.start(advertiseData: data);
      
      await Future.delayed(const Duration(seconds: 15));
      await _peripheral.stop();
      
    } catch (e) {
      debugPrint("Broadcast Error: $e");
    }
  }
}
