import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../core/services/printer_service.dart';

class PrinterProvider extends ChangeNotifier {
  final PrinterService _printerService = PrinterService();
  
  List<BluetoothInfo> _devices = [];
  bool _isLoading = false;
  bool _isConnecting = false;
  String? _connectingAddress;
  BluetoothInfo? _selectedDevice;
  bool _isBluetoothOn = true;
  bool _isPermissionGranted = true;
  Timer? _bluetoothMonitorTimer;

  // Getters
  List<BluetoothInfo> get devices => _devices;
  bool get isLoading => _isLoading;
  bool get isConnecting => _isConnecting;
  String? get connectingAddress => _connectingAddress;
  BluetoothInfo? get selectedDevice => _selectedDevice;
  bool get isBluetoothOn => _isBluetoothOn;
  bool get isPermissionGranted => _isPermissionGranted;
  int get paperSizeIndex => _printerService.paperSizeIndex;

  void init() {
    _selectedDevice = _printerService.device;
    loadDevices();
    _startBluetoothMonitor();
  }

  void _startBluetoothMonitor() {
    _bluetoothMonitorTimer?.cancel();
    _bluetoothMonitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final bool btOn = await PrintBluetoothThermal.bluetoothEnabled
          .timeout(const Duration(seconds: 1), onTimeout: () => false);
      
      if (btOn != _isBluetoothOn) {
        _isBluetoothOn = btOn;
        if (!btOn) {
          // Bluetooth turned off - clear selected printer
          _selectedDevice = null;
          _devices = [];
        } else {
          // Bluetooth turned back on - refresh list
          loadDevices();
        }
        notifyListeners();
      }
    });
  }

  Future<void> loadDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check permissions first
      if (Platform.isAndroid) {
        final status = await Permission.bluetoothConnect.status;
        _isPermissionGranted = status.isGranted;
      }

      final bool btOn = await PrintBluetoothThermal.bluetoothEnabled
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      _isBluetoothOn = btOn;
      
      if (!btOn) {
        _selectedDevice = null; // Clear if BT is off
        _devices = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final devices = await _printerService
          .getBondedDevices()
          .timeout(const Duration(seconds: 10), onTimeout: () => []);
      
      _devices = devices;
    } catch (_) {
      _devices = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(BluetoothInfo device) async {
    _isConnecting = true;
    _connectingAddress = device.macAdress;
    notifyListeners();
    
    final success = await _printerService.selectAndConnect(device);
    
    _isConnecting = false;
    _connectingAddress = null;
    if (success) {
      _selectedDevice = device;
    }
    notifyListeners();
    return success;
  }

  Future<void> setPaperSize(int sizeIndex) async {
    await _printerService.setPaperSize(sizeIndex);
    notifyListeners();
  }

  @override
  void dispose() {
    _bluetoothMonitorTimer?.cancel();
    super.dispose();
  }
}
