import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:lineless/models/order_model.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() => _instance;

  PrinterService._internal();

  static const _addressKey = 'bt_printer_address';
  static const _nameKey = 'bt_printer_name';
  static const _isEthernetKey = 'printer_is_ethernet';
  static const _ipAddressKey = 'printer_ip_address';
  static const _paperSizeKey = 'printer_paper_size';
  static const _qrEnabledKey = 'printer_qr_enabled';
  static const _upiIdKey = 'printer_upi_id';
  static const _kitchenExcludedKey = 'kitchen_excluded_products';

  static const _btCallTimeout = Duration(seconds: 3);

  BluetoothInfo? _device;
  BluetoothInfo? get device => _device;

  bool _isEthernet = false;
  bool get isEthernet => _isEthernet;

  String? _ipAddress;
  String? get ipAddress => _ipAddress;

  PaperSize _paperSize = PaperSize.mm58;
  PaperSize get paperSize => _paperSize;

  int _paperSizeIndex = 0; // 0: 58mm, 1: 80mm
  int get paperSizeIndex => _paperSizeIndex;

  bool _isQrEnabled = false;
  bool get isQrEnabled => _isQrEnabled;

  String _upiId = '';
  String get upiId => _upiId;

  bool get _hasPrinter =>
      _isEthernet ? (_ipAddress?.isNotEmpty ?? false) : _device != null;

  // GSTIN, pushed in from SettingsProvider, so queued/auto-printed receipts
  // (e.g. takeaway orders via GlobalAlertProvider) carry the GST number just
  // like receipts printed from a screen. The number prints whenever it is set,
  // regardless of whether GST is enabled; `enabled` is kept for call
  // compatibility but no longer gates the number.
  String _gstin = '';

  void setGstDetails({required bool enabled, required String gstin}) {
    _gstin = gstin;
  }

  // The GSTIN prints whenever one has been entered, even if GST is disabled.
  String? get _effectiveGstin =>
      _gstin.trim().isNotEmpty ? _gstin.trim() : null;

  Map<int, String> _kitchenExcluded = {};

  bool isKitchenEnabled(int productId) =>
      !_kitchenExcluded.containsKey(productId);

  bool isKitchenItem({int? productId, required String name}) {
    if (productId != null) return isKitchenEnabled(productId);
    final key = name.trim().toLowerCase();
    return !_kitchenExcluded.values.any((n) => n.trim().toLowerCase() == key);
  }

  Future<void> setKitchenPrint(Map<int, String> products, bool enabled) async {
    if (enabled) {
      products.keys.forEach(_kitchenExcluded.remove);
    } else {
      _kitchenExcluded.addAll(products);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kitchenExcludedKey,
      jsonEncode(
        _kitchenExcluded.map((id, name) => MapEntry(id.toString(), name)),
      ),
    );
  }

  Future<void> _lock = Future.value();

  Future<T> _runExclusive<T>(
    String label,
    T fallback,
    Future<T> Function() job,
  ) {
    final completer = Completer<T>();
    _lock = _lock.then((_) async {
      try {
        completer.complete(await job());
      } catch (e) {
        debugPrint('[PRINTER] $label error: $e');
        completer.complete(fallback);
      }
    });
    return completer.future;
  }

  CapabilityProfile? _cachedProfile;

  final List<OrderModel> _printQueue = [];

  // Server order ids whose customer receipt has already been printed. Shared by
  // the local place-order print and the realtime queue so the same bill is
  // never printed twice no matter which path reaches the printer first.
  final Set<String> _printedReceiptIds = {};

  bool get hasPendingPrints => _printQueue.isNotEmpty;
  List<OrderModel> get printQueue => List.unmodifiable(_printQueue);

  void enqueue(OrderModel order) {
    // Skip anything already printed (e.g. a POS order printed locally at
    // placement), so the realtime path won't produce a duplicate.
    if (order.id.isNotEmpty && _printedReceiptIds.contains(order.id)) return;
    if (!_printQueue.any((o) => o.id == order.id)) {
      _printQueue.add(order);
      debugPrint(
        '[PRINTER] Enqueued order #${order.tokenNumber}. Total in queue: ${_printQueue.length}',
      );
    }
  }

  Future<int> flushQueue({String? userName}) async {
    if (_printQueue.isEmpty) return 0;
    if (!_hasPrinter) {
      debugPrint('[PRINTER] flushQueue: ABORT — no printer configured');
      return 0;
    }

    return _runExclusive('flushQueue', 0, () async {
      if (_printQueue.isEmpty) return 0;
      debugPrint('[PRINTER] flushQueue: starting batch print...');

      final link = await _open();
      if (link == null) return 0;

      final printed = <String>[];
      final unprintable = <String>[];
      try {
        for (int i = 0; i < _printQueue.length; i++) {
          final order = _printQueue[i];

          // Already printed by the local place-order path → drop, don't reprint.
          if (order.id.isNotEmpty && _printedReceiptIds.contains(order.id)) {
            unprintable.add(order.id);
            continue;
          }

          final bytes = await _buildBytes(
            order,
            userName: userName,
            gstin: _effectiveGstin,
          );
          if (bytes == null) {
            debugPrint(
              '[PRINTER] Dropping unprintable order #${order.tokenNumber}',
            );
            unprintable.add(order.id);
            continue;
          }

          if (printed.isNotEmpty)
            await Future.delayed(const Duration(milliseconds: 1200));
          debugPrint(
            '[PRINTER] Printing ${i + 1}/${_printQueue.length} (Token #${order.tokenNumber})',
          );

          if (!await _send(link, bytes)) {
            debugPrint('[PRINTER] batch failed at Token #${order.tokenNumber}');
            break;
          }
          printed.add(order.id);
          if (order.id.isNotEmpty) _printedReceiptIds.add(order.id);
        }
      } finally {
        await _close(link);
        _printQueue.removeWhere(
          (o) => printed.contains(o.id) || unprintable.contains(o.id),
        );
      }
      return printed.length;
    });
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEthernet = prefs.getBool(_isEthernetKey) ?? false;
    _ipAddress = prefs.getString(_ipAddressKey);

    final address = prefs.getString(_addressKey);
    final name = prefs.getString(_nameKey);
    if (address != null && name != null) {
      _device = BluetoothInfo(name: name, macAdress: address);
    }

    _paperSizeIndex = prefs.getInt(_paperSizeKey) ?? 0;
    if (_paperSizeIndex == 1) {
      _paperSize = PaperSize.mm80;
    } else {
      _paperSize = PaperSize.mm58;
    }

    _isQrEnabled = prefs.getBool(_qrEnabledKey) ?? false;
    _upiId = prefs.getString(_upiIdKey) ?? '';

    final excluded = prefs.getString(_kitchenExcludedKey);
    if (excluded != null) {
      try {
        _kitchenExcluded = (jsonDecode(excluded) as Map<String, dynamic>).map(
          (id, name) => MapEntry(int.parse(id), name.toString()),
        );
      } catch (e) {
        debugPrint('[PRINTER] Could not read kitchen print items: $e');
      }
    }
  }

  Future<void> setPaperSize(int sizeIndex) async {
    _paperSizeIndex = sizeIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paperSizeKey, sizeIndex);

    if (sizeIndex == 1) {
      _paperSize = PaperSize.mm80;
    } else {
      _paperSize = PaperSize.mm58;
    }
  }

  Future<void> setQrSettings(bool enabled, String upiId) async {
    _isQrEnabled = enabled;
    _upiId = upiId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_qrEnabledKey, enabled);
    await prefs.setString(_upiIdKey, upiId);
  }

  Future<List<BluetoothInfo>> getBondedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> get isConnected async {
    if (_isEthernet) {
      if (_ipAddress == null || _ipAddress!.isEmpty) return false;
      try {
        final socket = await Socket.connect(
          _ipAddress!,
          9100,
          timeout: const Duration(seconds: 2),
        );
        await socket.close();
        return true;
      } catch (_) {
        return false;
      }
    }
    return await PrintBluetoothThermal.connectionStatus;
  }

  Future<bool> selectAndConnect(BluetoothInfo device) async {
    try {
      _device = device;
      _isEthernet = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_addressKey, device.macAdress);
      await prefs.setString(_nameKey, device.name);
      await prefs.setBool(_isEthernetKey, false);

      return _runExclusive('selectAndConnect', false, _ensureConnected);
    } catch (e) {
      return false;
    }
  }

  Future<bool> connectEthernet(String ipAddress) async {
    try {
      _ipAddress = ipAddress;
      _isEthernet = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ipAddressKey, ipAddress);
      await prefs.setBool(_isEthernetKey, true);

      final socket = await Socket.connect(
        ipAddress,
        9100,
        timeout: const Duration(seconds: 5),
      );
      await socket.close();
      return true;
    } catch (e) {
      debugPrint('[PRINTER] Ethernet connection failed: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_isEthernet) return;
    await _runExclusive<void>('disconnect', null, () async {
      await PrintBluetoothThermal.disconnect.timeout(_btCallTimeout);
    });
  }

  Future<bool> printReceipt(
    OrderModel order, {
    String? userName,
    String? gstin,
  }) async {
    final ok = await _printSingle(
      'printReceipt',
      order,
      userName: userName,
      gstin: gstin,
    );
    if (ok) _printQueue.removeWhere((o) => o.id == order.id);
    return ok;
  }

  /// Prints a customer receipt at most once per order id, coordinating with the
  /// realtime queue ([enqueue]/[flushQueue]) via [_printedReceiptIds] so the
  /// same bill is never printed twice regardless of which path prints first.
  /// Used to print a POS take-away bill locally the moment it is placed, so
  /// printing doesn't depend on the realtime socket being connected.
  Future<bool> printReceiptOnce(
    OrderModel order, {
    String? userName,
    String? gstin,
  }) async {
    if (!_hasPrinter) return false;
    final String id = order.id.trim();

    final bytes = await _buildBytes(order, userName: userName, gstin: gstin);
    if (bytes == null) return false;

    return _runExclusive('printReceiptOnce', false, () async {
      // Check-and-mark inside the exclusive lock so a near-simultaneous realtime
      // flush of the same order can't also print it.
      if (id.isNotEmpty && _printedReceiptIds.contains(id)) return true;

      final link = await _open();
      if (link == null) return false;
      bool ok = false;
      try {
        ok = await _send(link, bytes);
      } finally {
        await _close(link);
      }
      if (ok && id.isNotEmpty) {
        _printedReceiptIds.add(id);
        _printQueue.removeWhere((o) => o.id == id);
      }
      return ok;
    });
  }

  Future<bool> printKitchenTicket(OrderModel order, {String? userName}) {
    return _printSingle(
      'printKitchenTicket',
      order,
      userName: userName,
      isKitchenTicket: true,
    );
  }

  Future<bool> _printSingle(
    String label,
    OrderModel order, {
    String? userName,
    bool isKitchenTicket = false,
    String? gstin,
  }) async {
    if (!_hasPrinter) return false;

    final bytes = await _buildBytes(
      order,
      userName: userName,
      isKitchenTicket: isKitchenTicket,
      gstin: gstin,
    );
    if (bytes == null) return false;

    return _runExclusive(label, false, () async {
      final link = await _open();
      if (link == null) return false;
      try {
        return await _send(link, bytes);
      } finally {
        await _close(link);
      }
    });
  }

  Future<_PrinterLink?> _open() async {
    if (_isEthernet) {
      final socket = await Socket.connect(
        _ipAddress!,
        9100,
        timeout: const Duration(seconds: 5),
      );
      return _PrinterLink(socket);
    }

    final btOn = await PrintBluetoothThermal.bluetoothEnabled.timeout(
      _btCallTimeout,
      onTimeout: () => false,
    );
    if (!btOn) {
      debugPrint('[PRINTER] ABORT — Bluetooth is OFF');
      return null;
    }
    return await _ensureConnected() ? _PrinterLink(null) : null;
  }

  Future<bool> _send(_PrinterLink link, List<int> bytes) async {
    final socket = link.socket;
    if (socket != null) {
      socket.add(bytes);
      await socket.flush().timeout(const Duration(seconds: 10));
    } else {
      final ok = await PrintBluetoothThermal.writeBytes(
        bytes,
      ).timeout(const Duration(seconds: 10), onTimeout: () => false);
      if (!ok) return false;
    }
    link.bytesSent += bytes.length;
    return true;
  }

  Future<void> _close(_PrinterLink link) async {
    final socket = link.socket;
    try {
      if (socket != null) {
        await socket.close().timeout(const Duration(seconds: 5));
      } else {
        if (link.bytesSent > 0)
          await Future.delayed(_drainTime(link.bytesSent));
        await PrintBluetoothThermal.disconnect.timeout(_btCallTimeout);
      }
    } catch (e) {
      debugPrint('[PRINTER] close error: $e');
      socket?.destroy();
    }
  }

  Duration _drainTime(int bytes) => Duration(milliseconds: 1500 + bytes ~/ 2);

  Future<bool> _ensureConnected() async {
    try {
      await PrintBluetoothThermal.disconnect.timeout(_btCallTimeout);
      await Future.delayed(const Duration(milliseconds: 500));

      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: _device!.macAdress,
      ).timeout(const Duration(seconds: 8), onTimeout: () => false);

      if (connected) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      return connected;
    } catch (e) {
      return false;
    }
  }

  String _printable(String text) {
    return String.fromCharCodes(
      text
          .replaceAll(RegExp('[“”]'), '"')
          .replaceAll(RegExp('[‘’]'), "'")
          .replaceAll(RegExp('[–—]'), '-')
          .runes
          .map((r) => r <= 0xFF ? r : 0x3F),
    );
  }

  // A "New Dish" item keeps "New Dish" as its product name and stores the name
  // the user typed in its note. Show the typed name instead of the default
  // "New Dish" label on printouts.
  static bool _isNewDishItem(OrderItem item) =>
      item.name.trim().toLowerCase() == 'new dish' &&
      (item.note?.trim().isNotEmpty ?? false);

  static String _displayName(OrderItem item) =>
      _isNewDishItem(item) ? item.note!.trim() : item.name;

  Future<List<int>?> _buildBytes(
    OrderModel order, {
    String? userName,
    bool isKitchenTicket = false,
    String? gstin,
  }) async {
    try {
      _cachedProfile ??= await CapabilityProfile.load();
      final gen = Generator(_paperSize, _cachedProfile!);
      final bytes = <int>[];

      List<int> text(String value, {PosStyles styles = const PosStyles()}) =>
          gen.text(_printable(value), styles: styles);

      bytes.addAll(gen.reset());

      final int lineWidth = _paperSizeIndex == 1 ? 42 : 30;

      String pad(String left, String right) {
        final int gap = lineWidth - left.length - right.length;
        if (gap > 0) {
          return left + (' ' * gap) + right;
        }
        return '$left $right';
      }

      final String sep = '-' * lineWidth;
      final String dbl = '=' * lineWidth;

      final String orderDateTime = DateFormat(
        'dd MMM yyyy, hh:mm a',
      ).format(order.createdAt);
      final String currentPrintDateTime = DateFormat(
        'dd MMM yyyy, hh:mm a',
      ).format(DateTime.now());

      if (isKitchenTicket) {
        bytes.addAll(
          text(
            'KITCHEN COPY',
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
        );
        bytes.addAll(
          text(sep, styles: const PosStyles(align: PosAlign.center)),
        );
        bytes.addAll(
          text(
            '${order.orderType == 'dine_in' ? 'TABLE' : 'TOKEN'} ${order.tokenNumber}',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          ),
        );
        if (order.customerName.trim().isNotEmpty) {
          bytes.addAll(
            text(
              'Customer: ${order.customerName.trim()}',
              styles: const PosStyles(align: PosAlign.center, bold: true),
            ),
          );
        }
        if (order.customerMobile.trim().isNotEmpty) {
          bytes.addAll(
            text(
              'Mobile: ${order.customerMobile.trim()}',
              styles: const PosStyles(align: PosAlign.center, bold: true),
            ),
          );
        }
        if (userName != null && userName.isNotEmpty) {
          bytes.addAll(
            text(
              'Chef: $userName',
              styles: const PosStyles(align: PosAlign.center),
            ),
          );
        }
        bytes.addAll(
          text(orderDateTime, styles: const PosStyles(align: PosAlign.center)),
        );
        bytes.addAll(
          text(sep, styles: const PosStyles(align: PosAlign.center)),
        );
        bytes.addAll(
          text(
            'ITEMS',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          ),
        );
        bytes.addAll(
          text(sep, styles: const PosStyles(align: PosAlign.center)),
        );

        for (final item in order.items) {
          String formattedQty = item.quantity;
          if (item.unit?.toUpperCase() == 'KG') {
            double qty = double.tryParse(item.quantity) ?? 0;
            if (qty < 1) {
              formattedQty = '${(qty * 1000).toStringAsFixed(0)}gm';
            } else {
              formattedQty = '${qty.toStringAsFixed(2)}kg';
            }
          }
          // Plate items show just the quantity (no 'plt' suffix).

          // Clean the per-item note (strip customization price bits like (+₹30))
          // and collapse multi-line notes so it can sit next to the item. New
          // dishes carry their name in the note, so there is nothing to append.
          final itemNote = _isNewDishItem(item) ? null : item.note?.trim();
          String? cleanKitchenNote;
          if (itemNote != null && itemNote.isNotEmpty) {
            final cleaned = itemNote
                .replaceAll(RegExp(r'\s*\(\+?[₹Rs.]*\s*\d+\)'), '')
                .replaceAll(RegExp(r'\s*\(\+?\d+\)'), '')
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .join(', ');
            if (cleaned.isNotEmpty) cleanKitchenNote = cleaned;
          }

          // Print the note next to the item, e.g. "1 x Margherita Pizza >>> Jain".
          final itemLine = cleanKitchenNote != null
              ? '$formattedQty x ${_displayName(item)} >>> $cleanKitchenNote'
              : '$formattedQty x ${_displayName(item)}';
          bytes.addAll(
            text(
              itemLine,
              styles: const PosStyles(align: PosAlign.left, bold: true),
            ),
          );

          // Blank line between items so the kitchen copy isn't cramped.
          bytes.addAll(gen.emptyLines(1));
        }

        final note = order.specialNote?.trim();
        if (note != null && note.isNotEmpty) {
          bytes.addAll(
            text(sep, styles: const PosStyles(align: PosAlign.center)),
          );
          bytes.addAll(
            text(
              'NOTE:',
              styles: const PosStyles(
                align: PosAlign.left,
                bold: true,
                height: PosTextSize.size2,
              ),
            ),
          );
          for (final line in note.split('\n')) {
            if (line.trim().isEmpty) continue;
            bytes.addAll(
              text(
                line.trim(),
                styles: const PosStyles(align: PosAlign.left, bold: true),
              ),
            );
          }
        }

        bytes.addAll(
          text(sep, styles: const PosStyles(align: PosAlign.center)),
        );
        bytes.addAll(gen.feed(1));
        bytes.addAll(gen.cut());
        return bytes;
      }

      // Main Receipt Header
      bytes.addAll(
        text('Bill Of Supply', styles: const PosStyles(align: PosAlign.center)),
      );
      bytes.addAll(
        text(
          userName ?? 'BillJi',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
      );

      // GST number: printed whenever a GSTIN has been entered, regardless of
      // whether GST is enabled, with the "Inclusive of supply" note beneath it.
      // Padded with a blank line above and below so it stands apart.
      if (gstin != null && gstin.trim().isNotEmpty) {
        bytes.addAll(gen.emptyLines(1));
        bytes.addAll(
          text(
            'GSTIN: ${gstin.trim()}',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          ),
        );
        bytes.addAll(
          text(
            'Inclusive of GST',
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
        bytes.addAll(gen.emptyLines(1));
      }

      bytes.addAll(text(sep, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(
        text(
          '${order.orderType == 'dine_in' ? 'TABLE' : 'TOKEN'}  ${order.tokenNumber}',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
      );
      bytes.addAll(text(sep, styles: const PosStyles(align: PosAlign.center)));

      // Customer Info
      bytes.addAll(
        text(
          pad('Date', currentPrintDateTime),
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
      bytes.addAll(
        text(
          pad('Customer', order.customerName),
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
      );
      bytes.addAll(
        text(
          pad('Mobile', order.customerMobile),
          styles: const PosStyles(align: PosAlign.center),
        ),
      );

      bytes.addAll(text(sep, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(
        text(
          'ITEMS',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
      );
      bytes.addAll(text(sep, styles: const PosStyles(align: PosAlign.center)));

      // Items
      for (final item in order.items) {
        String formattedQty = item.quantity;
        if (item.unit?.toUpperCase() == 'KG') {
          double qty = double.tryParse(item.quantity) ?? 0;
          if (qty < 1) {
            formattedQty = '${(qty * 1000).toStringAsFixed(0)} gm';
          } else {
            formattedQty = '${qty.toStringAsFixed(2)} kg';
          }
        }
        // Plate items show just the quantity (no 'Plt' suffix).

        double totalAmount =
            item.total ?? (item.price * (double.tryParse(item.quantity) ?? 0));
        final left = '$formattedQty x ${_displayName(item)}';
        final right = 'Rs.${totalAmount.toStringAsFixed(0)}';

        bytes.addAll(
          text(
            pad(left, right),
            styles: const PosStyles(align: PosAlign.center),
          ),
        );

        // Show the customization / sub-category note under the item, the same
        // way it appears on the kitchen ticket, keeping any add-on price
        // (e.g. ">>> Extra Cheese (+Rs.30)"). New dishes have no extra note.
        if (!_isNewDishItem(item)) {
          final billNote = item.note?.trim();
          if (billNote != null && billNote.isNotEmpty) {
            final printable = billNote.replaceAll('₹', 'Rs.');
            bytes.addAll(
              text(
                '  >>> $printable',
                styles: const PosStyles(align: PosAlign.left),
              ),
            );
          }
        }
      }

      bytes.addAll(text(dbl, styles: const PosStyles(align: PosAlign.center)));
      if (order.gstAmount != null && order.gstAmount! > 0) {
        final double subtotal =
            order.subtotalAmount ?? (order.totalAmount - order.gstAmount!);
        final double cgst = order.cgstAmount ?? (order.gstAmount! / 2);
        final double sgst = order.sgstAmount ?? (order.gstAmount! / 2);
        // Effective CGST/SGST rate (half of the total GST rate).
        final double halfRatePct = subtotal > 0
            ? (order.gstAmount! / subtotal * 100) / 2
            : 0;
        final String rateStr = halfRatePct.toStringAsFixed(2);

        bytes.addAll(
          text(
            pad('Sub Total', 'Rs.${subtotal.toStringAsFixed(2)}'),
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
        bytes.addAll(
          text(
            pad('CGST @$rateStr%', 'Rs.${cgst.toStringAsFixed(2)}'),
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
        bytes.addAll(
          text(
            pad('SGST @$rateStr%', 'Rs.${sgst.toStringAsFixed(2)}'),
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
        bytes.addAll(
          text(sep, styles: const PosStyles(align: PosAlign.center)),
        );
      }
      bytes.addAll(
        text(
          pad('TOTAL', 'Rs.${order.totalAmount.toStringAsFixed(2)}'),
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
      );
      bytes.addAll(text(dbl, styles: const PosStyles(align: PosAlign.center)));

      // QR Code Section
      if (_isQrEnabled && _upiId.isNotEmpty) {
        bytes.addAll(gen.feed(1));
        bytes.addAll(
          text(
            'Scan to Pay',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          ),
        );

        final String upiUrl =
            'upi://pay?pa=${_upiId.trim()}&pn=${Uri.encodeComponent(userName ?? 'Merchant')}&am=${order.totalAmount}&cu=INR';

        bytes.addAll(
          gen.qrcode(
            upiUrl,
            size: QRSize.size6,
            cor: QRCorrection.L,
            align: PosAlign.center,
          ),
        );
        bytes.addAll(gen.feed(1));
      }

      if (order.specialNote != null && order.specialNote!.isNotEmpty) {
        bytes.addAll(
          text(
            'Note: ${order.specialNote}',
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
        bytes.addAll(
          text(sep, styles: const PosStyles(align: PosAlign.center)),
        );
      }

      // Footer
      bytes.addAll(
        text(
          'Thank you!',
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size1,
          ),
        ),
      );
      bytes.addAll(
        text('BillJi', styles: const PosStyles(align: PosAlign.center)),
      );

      bytes.addAll(gen.feed(1));
      bytes.addAll(gen.cut());
      return bytes;
    } catch (e) {
      debugPrint(
        '[PRINTER] Could not build ticket for #${order.tokenNumber}: $e',
      );
      return null;
    }
  }
}

class _PrinterLink {
  final Socket? socket;
  int bytesSent = 0;

  _PrinterLink(this.socket);
}
