import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/services/printer_service.dart';
import '../core/network/reverb_service.dart';
import '../core/di/injection.dart';
import '../providers/order_provider.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../core/utils/resource.dart';
import '../models/order_model.dart';

class GlobalAlertProvider extends ChangeNotifier {
  final ReverbService _reverbService = sl<ReverbService>();
  final AuthLocalDataSource _localDataSource = sl<AuthLocalDataSource>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  StreamSubscription? _reverbSubscription;
  bool _showNotification = false;
  int _newOrdersCount = 0;
  bool _isProcessing = false;
  bool _needsRefresh = false;
  
  final Set<String> _processedOrderIds = {};
  final String _alertSoundUrl = 'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3';

  // Getters
  bool get showNotification => _showNotification;
  int get newOrdersCount => _newOrdersCount;

  void init(OrderProvider orderProvider) {
    _reverbService.connect();
    
    _reverbSubscription?.cancel();
    _reverbSubscription = _reverbService.eventStream.listen((event) {
      if (event['event'] == 'dashboard.updated') {
        final rawData = event['data'];
        Map<String, dynamic>? data;
        try {
          if (rawData is String) data = jsonDecode(rawData);
          else if (rawData is Map) data = Map<String, dynamic>.from(rawData);
        } catch (_) {}

        final eventUserId = data?['user_id']?.toString();
        final currentMyUserId = _localDataSource.getUserId();

        if (eventUserId != null && currentMyUserId != null && eventUserId != currentMyUserId) {
          log('[GLOBAL ALERT] Ignored update for restaurant $eventUserId');
          return;
        }

        log('[GLOBAL ALERT] dashboard.updated received');
        if (_isProcessing) {
          _needsRefresh = true;
          log('[GLOBAL ALERT] Already processing, flagged for re-run');
        } else {
          _processEvent(orderProvider);
        }
      }
    });
  }

  Future<void> _processEvent(OrderProvider orderProvider) async {
    _isProcessing = true;
    _needsRefresh = false;
    notifyListeners();

    try {
      final loggedInUserId = _localDataSource.getUserId();

      log('[GLOBAL ALERT] Fetching dashboard updates...');
      await orderProvider.fetchDashboard(isRealtime: true);

      // Capture the new orders immediately: fetchDashboard clears `newOrders`
      // after a few seconds, so reading it only after another await (e.g. the
      // tables fetch below) could miss them and skip the print.
      final dashboardUserId = orderProvider.dashboardData?.userId.toString();
      final List<OrderModel> newOrders = (dashboardUserId != null && dashboardUserId == loggedInUserId)
          ? orderProvider.newOrders.where((o) => !_processedOrderIds.contains(o.id)).toList()
          : <OrderModel>[];

      if (dashboardUserId != null && dashboardUserId == loggedInUserId) {
        if (newOrders.isNotEmpty) {
          log('[GLOBAL ALERT] Found ${newOrders.length} new order(s)');
          
          _newOrdersCount = newOrders.length;
          _showNotification = true;
          notifyListeners();

          final printer = PrinterService();
          
          // Auto-print receipts only for takeaway/POS/QR orders or finalized completed orders.
          // Active dine-in table sessions (status = pending/running) only auto-sync in background
          // and should NOT auto-print receipts while adding items.
          for (final order in newOrders) {
            _processedOrderIds.add(order.id);

            final bool isDineIn = (order.orderType ?? '').toLowerCase() == 'dine_in';
            final bool isUnfinalizedDineIn = isDineIn && (order.status == OrderStatus.pending || order.status == OrderStatus.running);

            if (!isUnfinalizedDineIn) {
              printer.enqueue(order);
            }
          }

          _playMultiAlert(newOrders.length);

          // Print and AWAIT it. Awaiting keeps _isProcessing true for the whole
          // print, so orders that arrive back-to-back are queued (via
          // _needsRefresh) and printed one after another instead of racing
          // overlapping print/connect cycles on the single printer. Retry a few
          // times so a transient printer/Bluetooth hiccup doesn't silently drop
          // the bill (a failed flush leaves the order queued).
          final bool printerReady = printer.device != null || printer.isEthernet;
          if (printerReady) {
            for (int attempt = 0; attempt < 3 && printer.hasPendingPrints; attempt++) {
              if (attempt > 0) await Future.delayed(const Duration(milliseconds: 1500));
              await printer.flushQueue(userName: orderProvider.dashboardData?.userName);
            }
          }

          Future.delayed(const Duration(seconds: 10), () {
            _showNotification = false;
            notifyListeners();
          });
        }
      }

      // Refresh the occupied-tables data last (after the time-sensitive print
      // detection) so a new/updated dine-in order's amount and details appear
      // on the dashboard without a manual refresh.
      await orderProvider.fetchPendingTables();
    } catch (e) {
      log('[GLOBAL ALERT] Error processing event: $e');
    } finally {
      _isProcessing = false;
      if (_needsRefresh) {
        Future.delayed(const Duration(seconds: 2), () => _processEvent(orderProvider));
      }
      notifyListeners();
    }
  }

  Future<void> _playMultiAlert(int count) async {
    for (int i = 0; i < count; i++) {
      await _playSound();
      if (i < count - 1) await Future.delayed(const Duration(milliseconds: 2000));
    }
  }

  Future<void> _playSound() async {
    try {
      if (_localDataSource.getAlertToneStatus()) {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(_alertSoundUrl));
      }
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  void dismissNotification() {
    _showNotification = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _reverbSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
