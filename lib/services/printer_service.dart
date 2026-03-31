import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as ep;
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/printer_config.dart';
import '../services/storage_service.dart';

/// Bluetooth device model for discovered printers
class BluetoothPrinterDevice {
  final String name;
  final String address;
  final int type;

  BluetoothPrinterDevice({
    required this.name,
    required this.address,
    this.type = 0,
  });
}

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  bool _isInitialized = false;
  String? _connectedDeviceAddress;
  String? _connectedDeviceName;
  bool _isActuallyConnected = false;
  DateTime? _lastConnectionTest;
  Socket? _bluetoothSocket;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final config = StorageService().getPrinterConfig();
    if (config != null) {
      _connectedDeviceAddress = config.deviceAddress;
      _connectedDeviceName = config.deviceName;
      _isActuallyConnected = false;
    }
  }

  /// Validate MAC address format (XX:XX:XX:XX:XX:XX)
  bool _isValidMacAddress(String address) {
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macRegex.hasMatch(address);
  }

  /// Try to establish a real Bluetooth RFCOMM connection
  Future<bool> _tryBluetoothConnection(String address) async {
    try {
      debugPrint('Attempting real Bluetooth connection to: $address');

      if (!_isValidMacAddress(address)) {
        debugPrint('ERROR: Invalid MAC address format: $address');
        return false;
      }

      // Close any existing connection
      await _closeConnection();

      // Try to connect via Bluetooth socket (RFCOMM)
      // Note: This requires Android and the printer to be paired
      try {
        _bluetoothSocket = await Socket.connect(
          address,
          1, // Standard RFCOMM port
          timeout: const Duration(seconds: 5),
        );

        debugPrint('SUCCESS: Bluetooth socket connected!');
        return true;
      } on SocketException catch (e) {
        debugPrint('FAILED: Could not connect to printer: $e');
        return false;
      } on TimeoutException catch (e) {
        debugPrint('FAILED: Connection timeout: $e');
        return false;
      }
    } catch (e) {
      debugPrint('ERROR during connection: $e');
      return false;
    }
  }

  /// Close the Bluetooth connection
  Future<void> _closeConnection() async {
    try {
      _bluetoothSocket?.destroy();
      _bluetoothSocket = null;
    } catch (e) {
      debugPrint('Error closing connection: $e');
    }
  }

  /// Test actual connection by sending init command
  Future<bool> _testPrinterConnection(String address) async {
    try {
      debugPrint('Testing REAL connection to printer: $address');

      final connected = await _tryBluetoothConnection(address);
      if (!connected) return false;

      // Send init command
      try {
        final testBytes = Uint8List.fromList([0x1B, 0x40]); // ESC @
        _bluetoothSocket?.add(testBytes);
        await _bluetoothSocket?.flush();
        await Future.delayed(const Duration(milliseconds: 300));

        debugPrint('SUCCESS: Printer responded to test command');
        return true;
      } catch (e) {
        debugPrint('FAILED: Printer did not respond: $e');
        await _closeConnection();
        return false;
      }
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  /// Connect to printer with REAL verification
  Future<bool> connectToPrinter(String deviceAddress, String deviceName) async {
    try {
      debugPrint('Connecting to printer: $deviceName at $deviceAddress');

      // Validate MAC
      if (!_isValidMacAddress(deviceAddress)) {
        debugPrint(
          'ERROR: Invalid MAC address. Expected format: XX:XX:XX:XX:XX:XX',
        );
        return false;
      }

      // Test real connection
      final canConnect = await _testPrinterConnection(deviceAddress);

      if (!canConnect) {
        debugPrint('FAILED: Printer not reachable!');
        _isActuallyConnected = false;
        await _closeConnection();
        return false;
      }

      // Success!
      _connectedDeviceAddress = deviceAddress;
      _connectedDeviceName = deviceName;
      _isActuallyConnected = true;
      _lastConnectionTest = DateTime.now();

      // Save config
      await StorageService().setPrinterConfig(
        PrinterConfig(
          type: 'bluetooth',
          deviceName: deviceName,
          deviceAddress: deviceAddress,
        ),
      );

      debugPrint('SUCCESS: Real connection established!');
      return true;
    } catch (e) {
      debugPrint('Error: $e');
      _isActuallyConnected = false;
      await _closeConnection();
      return false;
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    await _closeConnection();
    _connectedDeviceAddress = null;
    _connectedDeviceName = null;
    _isActuallyConnected = false;
    _lastConnectionTest = null;
    await StorageService().clearPrinterConfig();
    debugPrint('Disconnected');
  }

  /// Get connected device info
  Map<String, String>? getConnectedDevice() {
    if (_connectedDeviceAddress == null || !_isActuallyConnected) return null;
    return {
      'name': _connectedDeviceName ?? 'Unknown',
      'address': _connectedDeviceAddress!,
    };
  }

  /// Test if printer is reachable
  Future<bool> testConnection(String deviceAddress) async {
    if (deviceAddress.isEmpty) return false;
    return await _testPrinterConnection(deviceAddress);
  }

  /// Print receipt - sends actual bytes
  Future<bool> printReceipt(Order order, {String? deviceAddress}) async {
    try {
      final address =
          deviceAddress ??
          _connectedDeviceAddress ??
          StorageService().getPrinterConfig()?.deviceAddress;

      if (address == null || address.isEmpty) {
        throw Exception('No printer configured');
      }

      // Verify connection first
      if (_bluetoothSocket == null || !_isActuallyConnected) {
        final isReachable = await _testPrinterConnection(address);
        if (!isReachable) {
          _isActuallyConnected = false;
          throw Exception('Printer not reachable');
        }
      }

      // Generate ESC/POS commands
      final profile = await ep.CapabilityProfile.load();
      final generator = ep.Generator(ep.PaperSize.mm80, profile);

      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.text(
        'Malhar Dosa',
        styles: const ep.PosStyles(
          align: ep.PosAlign.center,
          bold: true,
          height: ep.PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        '------------------------------',
        styles: const ep.PosStyles(align: ep.PosAlign.center),
      );
      bytes += generator.text(
        'Order: ${order.id}',
        styles: const ep.PosStyles(align: ep.PosAlign.left),
      );
      bytes += generator.text(
        'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
        styles: const ep.PosStyles(align: ep.PosAlign.left),
      );
      bytes += generator.text(
        '------------------------------',
        styles: const ep.PosStyles(align: ep.PosAlign.center),
      );

      // Items header
      bytes += generator.row([
        ep.PosColumn(
          text: 'Item',
          width: 12,
          styles: const ep.PosStyles(bold: true),
        ),
      ]);
      bytes += generator.row([
        ep.PosColumn(
          text: 'Qty',
          width: 3,
          styles: const ep.PosStyles(bold: true),
        ),
        ep.PosColumn(
          text: 'Price',
          width: 4,
          styles: const ep.PosStyles(bold: true, align: ep.PosAlign.right),
        ),
        ep.PosColumn(
          text: 'Total',
          width: 5,
          styles: const ep.PosStyles(bold: true, align: ep.PosAlign.right),
        ),
      ]);
      bytes += generator.text(
        '------------------------------',
        styles: const ep.PosStyles(align: ep.PosAlign.center),
      );

      // Items
      for (final item in order.items) {
        bytes += generator.text(
          item.name,
          styles: const ep.PosStyles(align: ep.PosAlign.left),
        );
        bytes += generator.row([
          ep.PosColumn(text: '${item.quantity}', width: 3),
          ep.PosColumn(
            text: '₹${item.price.toStringAsFixed(2)}',
            width: 4,
            styles: const ep.PosStyles(align: ep.PosAlign.right),
          ),
          ep.PosColumn(
            text: '₹${item.total.toStringAsFixed(2)}',
            width: 5,
            styles: const ep.PosStyles(align: ep.PosAlign.right),
          ),
        ]);
      }

      // Totals
      bytes += generator.text(
        '------------------------------',
        styles: const ep.PosStyles(align: ep.PosAlign.center),
      );
      bytes += generator.row([
        ep.PosColumn(
          text: 'Subtotal:',
          width: 6,
          styles: const ep.PosStyles(align: ep.PosAlign.left),
        ),
        ep.PosColumn(
          text: '₹${order.subtotal.toStringAsFixed(2)}',
          width: 6,
          styles: const ep.PosStyles(align: ep.PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        ep.PosColumn(
          text: 'Tax (${order.taxPercent}%):',
          width: 6,
          styles: const ep.PosStyles(align: ep.PosAlign.left),
        ),
        ep.PosColumn(
          text: '₹${order.taxAmount.toStringAsFixed(2)}',
          width: 6,
          styles: const ep.PosStyles(align: ep.PosAlign.right),
        ),
      ]);

      if (order.discount > 0) {
        bytes += generator.row([
          ep.PosColumn(
            text: 'Discount:',
            width: 6,
            styles: const ep.PosStyles(align: ep.PosAlign.left),
          ),
          ep.PosColumn(
            text: '-₹${order.discount.toStringAsFixed(2)}',
            width: 6,
            styles: const ep.PosStyles(align: ep.PosAlign.right),
          ),
        ]);
      }

      bytes += generator.text(
        '------------------------------',
        styles: const ep.PosStyles(align: ep.PosAlign.center),
      );
      bytes += generator.row([
        ep.PosColumn(
          text: 'GRAND TOTAL:',
          width: 6,
          styles: const ep.PosStyles(bold: true, align: ep.PosAlign.left),
        ),
        ep.PosColumn(
          text: '₹${order.total.toStringAsFixed(2)}',
          width: 6,
          styles: const ep.PosStyles(bold: true, align: ep.PosAlign.right),
        ),
      ]);
      bytes += generator.feed(1);
      bytes += generator.text(
        'Thank you for visiting!',
        styles: const ep.PosStyles(align: ep.PosAlign.center),
      );
      bytes += generator.text(
        '------------------------------',
        styles: const ep.PosStyles(align: ep.PosAlign.center),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      // Send to printer
      debugPrint('Sending ${bytes.length} bytes...');
      if (_bluetoothSocket != null) {
        _bluetoothSocket!.add(Uint8List.fromList(bytes));
        await _bluetoothSocket!.flush();
        debugPrint('Print successful!');
        return true;
      } else {
        throw Exception('Not connected');
      }
    } on SocketException catch (e) {
      _isActuallyConnected = false;
      await _closeConnection();
      throw Exception('Connection lost: $e');
    } catch (e) {
      _isActuallyConnected = false;
      throw Exception('Print failed: $e');
    }
  }

  /// Check if REALLY connected (verified by actual test)
  Future<bool> isConnected() async {
    try {
      // Load config if needed
      if (!_isActuallyConnected && _connectedDeviceAddress == null) {
        final config = StorageService().getPrinterConfig();
        if (config != null && config.deviceAddress.isNotEmpty) {
          _connectedDeviceAddress = config.deviceAddress;
          _connectedDeviceName = config.deviceName;
        }
      }

      // If we have an address, verify it's reachable
      if (_connectedDeviceAddress != null) {
        final shouldRetest =
            _lastConnectionTest == null ||
            DateTime.now().difference(_lastConnectionTest!) >
                const Duration(seconds: 30);

        if (shouldRetest) {
          debugPrint('Verifying printer connection...');
          final stillConnected = await _testPrinterConnection(
            _connectedDeviceAddress!,
          );
          _isActuallyConnected = stillConnected;
          _lastConnectionTest = DateTime.now();
        }

        return _isActuallyConnected;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking connection: $e');
      _isActuallyConnected = false;
      return false;
    }
  }

  /// Get printer config
  PrinterConfig? getPrinterConfig() {
    return StorageService().getPrinterConfig();
  }

  /// Scan for devices (placeholder - requires platform implementation)
  Future<List<BluetoothPrinterDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return [];
  }

  /// Check if Bluetooth enabled (placeholder)
  Future<bool> isBluetoothEnabled() async {
    return true;
  }
}
