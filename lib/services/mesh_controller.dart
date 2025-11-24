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
    // Request Permissions (Updated for Android 13/14/15)
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check support (V2 API)
    final isSupported = await _peripheral.isSupported;
    if (isSupported) {
      startScanning();
      _startPacketRotation();
    }
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

    // FIX: allowDuplicates removed in 1.34+. 
    // AndroidScanMode.lowLatency implies continuous scanning.
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
          final AdvertiseData data = AdvertiseData(
            manufacturerId: 0xFFFF,
            manufacturerData: Uint8List.fromList(packet),
            includeDeviceName: false,
          );
          await _peripheral.start(advertiseData: data);
        }
      } catch (e) { debugPrint("Rotation Error: $e"); }
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
    } catch (e) { debugPrint("Broadcast Error: $e"); }
  }
  
  Future<void> stop() async {
    _isScanning = false;
    _rotationTimer?.cancel();
    await FlutterBluePlus.stopScan();
    await _peripheral.stop();
  }
}
