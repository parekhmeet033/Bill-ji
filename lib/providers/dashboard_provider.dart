import 'dart:async';
import 'package:flutter/material.dart';
import 'order_provider.dart';
import 'table_provider.dart';
import '../presentation/providers/auth_provider.dart';

class DashboardProvider extends ChangeNotifier {
  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  Timer? _refreshTimer;

  void startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      notifyListeners();
    });
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void setTabIndex(int index) {
    if (_tabIndex != index) {
      _tabIndex = index;
      notifyListeners();
    }
  }

  Future<void> initialize({
    required OrderProvider orderProvider,
    required AuthProvider authProvider,
    required TableProvider tableProvider,
  }) async {
    // Start periodic refresh for UI elements like occupied time
    startPeriodicRefresh();

    // Initial data fetch
    await Future.wait([
      orderProvider.fetchDashboard(),
      orderProvider.fetchPendingTables(),
    ]);

    // Sync tables count
    tableProvider.syncTablesWithCount(authProvider.tableCount);
  }

  @override
  void dispose() {
    stopPeriodicRefresh();
    super.dispose();
  }

  void reset() {
    _tabIndex = 0;
    stopPeriodicRefresh();
    notifyListeners();
  }
}
