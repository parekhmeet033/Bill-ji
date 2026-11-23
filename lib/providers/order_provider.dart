import 'package:flutter/material.dart';
import 'package:lineless/core/error/failures.dart';
import '../core/utils/resource.dart';
import '../domain/usecases/get_orders_usecase.dart';
import '../domain/usecases/get_dashboard_usecase.dart';
import '../domain/usecases/get_orders_list_usecase.dart';
import '../domain/usecases/get_pending_tables_usecase.dart';
import '../domain/usecases/get_reports_analytics_usecase.dart';
import '../domain/usecases/update_order_status_usecase.dart';
import '../domain/usecases/delete_orders_usecase.dart';
import '../domain/usecases/forgot_pin_usecase.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../models/order_model.dart';
import '../models/dashboard_model.dart';
import '../models/pagination_model.dart';
import '../models/report_model.dart';
import '../models/pending_table_model.dart';

class OrderProvider extends ChangeNotifier {
  final GetOrdersUseCase? getOrdersUseCase;
  final GetDashboardUseCase? getDashboardUseCase;
  final GetOrdersListUseCase? getOrdersListUseCase;
  final GetPendingTablesUseCase? getPendingTablesUseCase;
  final GetReportsAnalyticsUseCase? getReportsAnalyticsUseCase;
  final UpdateOrderStatusUseCase? updateOrderStatusUseCase;
  final DeleteOrdersUseCase? deleteOrdersUseCase;
  final ForgotPinUseCase? forgotPinUseCase;
  final AuthLocalDataSource? authLocalDataSource;

  OrderProvider({
    this.getOrdersUseCase,
    this.getDashboardUseCase,
    this.getOrdersListUseCase,
    this.getPendingTablesUseCase,
    this.getReportsAnalyticsUseCase,
    this.updateOrderStatusUseCase,
    this.deleteOrdersUseCase,
    this.forgotPinUseCase,
    this.authLocalDataSource,
  });

  List<OrderModel> _orders = [];
  Resource<List<OrderModel>> _ordersResource = Initial();

  // Every order id loaded so far. New orders are detected against this, not
  // against [_orders]: that list gets replaced and trimmed (a dispatched order
  // is removed), which made old orders look new and auto-print a second time.
  final Set<String> _seenOrderIds = {};
  bool _hasLoadedOrders = false;

  void _rememberOrders(List<OrderModel> orders) {
    _seenOrderIds.addAll(orders.map((o) => o.id));
    _hasLoadedOrders = true;
  }

  DashboardData? _dashboardData;
  Resource<DashboardData> _dashboardResource = Initial();

  // For pending tables
  List<PendingTableModel> _pendingTables = [];
  Resource<List<PendingTableModel>> _pendingTablesResource = Initial();

  // For paginated orders list
  List<OrderModel> _allOrders = [];
  Resource<List<OrderModel>> _allOrdersResource = Initial();
  Pagination? _pagination;

  // For reports
  ReportData? _reportData;
  Resource<ReportData> _reportResource = Initial();

  // Real-time animation triggers
  String? _newOrderId;
  String? _statusChangedOrderId;
  bool _shouldBlinkToken = false;
  List<OrderModel> _newOrders = [];

  List<OrderModel> get orders => _orders;

  Resource<List<OrderModel>> get ordersResource => _ordersResource;

  DashboardData? get dashboardData => _dashboardData;

  Resource<DashboardData> get dashboardResource => _dashboardResource;

  List<PendingTableModel> get pendingTables => _pendingTables;

  Resource<List<PendingTableModel>> get pendingTablesResource => _pendingTablesResource;

  List<OrderModel> get allOrders => _allOrders;

  Resource<List<OrderModel>> get allOrdersResource => _allOrdersResource;

  Pagination? get pagination => _pagination;

  ReportData? get reportData => _reportData;

  Resource<ReportData> get reportResource => _reportResource;

  String? get newOrderId => _newOrderId;

  String? get statusChangedOrderId => _statusChangedOrderId;

  bool get shouldBlinkToken => _shouldBlinkToken;

  List<OrderModel> get newOrders => _newOrders;

  // Recent Orders for the Takeaway tab: every non-dine-in order (QR + POS, which
  // share one sequential token series), EXCLUDING dispatched and cancelled
  // orders — once an order is dispatched or cancelled it leaves the list.
  List<OrderModel> get takeawayOrders => _orders
      .where((o) =>
          (o.orderType ?? '').toLowerCase() != 'dine_in' &&
          o.status != OrderStatus.dispatched &&
          o.status != OrderStatus.cancelled)
      .toList();

  List<OrderModel> get pendingOrders => _orders.where((o) => o.status == OrderStatus.pending).toList();

  List<OrderModel> get runningOrders => _orders.where((o) => o.status == OrderStatus.running).toList();

  List<OrderModel> get completedOrders => _orders.where((o) => o.status == OrderStatus.completed).toList();

  Future<void> fetchOrders() async {
    if (getOrdersUseCase == null) return;

    _ordersResource = Loading();
    notifyListeners();

    _ordersResource = await getOrdersUseCase!.execute();
    if (_ordersResource is Success) {
      _orders = List<OrderModel>.from(_ordersResource.data ?? []);
      _rememberOrders(_orders);
    }
    notifyListeners();
  }

  Future<void> fetchDashboard({bool isRealtime = false}) async {
    if (getDashboardUseCase == null) return;

    if (!isRealtime) {
      _dashboardResource = Loading();
      notifyListeners();
    }

    final result = await getDashboardUseCase!.execute();
    if (result is Success) {
      if (isRealtime) {
        _dashboardData = result.data;
        _orders = List<OrderModel>.from(_dashboardData?.recentOrders ?? []);

        // Sync local settings from dashboard response in realtime too
        if (authLocalDataSource != null && _dashboardData != null) {
          authLocalDataSource!.saveRestaurantMode(_dashboardData!.oprationModeStatus);
          authLocalDataSource!.saveTableCount(_dashboardData!.numberOfTables);
        }

        // Blink token on every realtime push
        _shouldBlinkToken = true;

        // Only animate truly new orders (never loaded before). Until the first
        // load there's nothing to compare with, so nothing counts as new;
        // otherwise every recent order would auto-print at once.
        _newOrders = _hasLoadedOrders ? _orders.where((o) => !_seenOrderIds.contains(o.id)).toList() : [];
        _rememberOrders(_orders);
        _newOrderId = _newOrders.isNotEmpty ? _newOrders.first.id : null;

        notifyListeners();

        Future.delayed(const Duration(seconds: 3), () {
          _newOrderId = null;
          _newOrders = [];
          _shouldBlinkToken = false;
          notifyListeners();
        });
      } else {
        _dashboardData = result.data;
        _orders = List<OrderModel>.from(_dashboardData?.recentOrders ?? []);
        _rememberOrders(_orders);

        // Sync local settings from dashboard response
        if (authLocalDataSource != null && _dashboardData != null) {
          authLocalDataSource!.saveRestaurantMode(_dashboardData!.oprationModeStatus);
          authLocalDataSource!.saveTableCount(_dashboardData!.numberOfTables);
        }

        _dashboardResource = Success(_dashboardData!);
        notifyListeners();
      }
    } else if (result is Error && !isRealtime) {
      _dashboardResource = Error(result.failure!);
      notifyListeners();
    }
  }

  Future<void> fetchPendingTables() async {
    if (getPendingTablesUseCase == null) return;

    _pendingTablesResource = Loading();
    notifyListeners();

    final result = await getPendingTablesUseCase!.execute();
    if (result is Success) {
      _pendingTables = List<PendingTableModel>.from(result.data ?? []);
      _pendingTablesResource = Success(_pendingTables);
    } else if (result is Error) {
      _pendingTablesResource = Error(result.failure!);
    }
    notifyListeners();
  }

  Future<void> fetchOrdersList({
    String status = 'All',
    String orderType = 'All',
    String search = '',
    String startDate = '',
    String endDate = '',
    int page = 1,
    bool isRefresh = true,
  }) async {
    if (getOrdersListUseCase == null) return;

    if (isRefresh) {
      _allOrdersResource = Loading();
      _allOrders = [];
      _pagination = null;
    } else {
      if (_pagination != null && page > _pagination!.lastPage) return;
    }
    notifyListeners();

    final result = await getOrdersListUseCase!.execute(
      status: status,
      orderType: orderType,
      search: search,
      startDate: startDate,
      endDate: endDate,
      page: page,
    );

    if (result is Success) {
      final paginatedData = result.data!;
      if (isRefresh) {
        _allOrders = List<OrderModel>.from(paginatedData.data);
      } else {
        _allOrders.addAll(paginatedData.data);
      }
      _pagination = paginatedData.pagination;
      _allOrdersResource = Success(_allOrders);
    } else if (result is Error) {
      _allOrdersResource = Error(result.failure!);
    }
    notifyListeners();
  }

  Future<void> fetchReports({String? userPin, String? startDate, String? endDate}) async {
    if (getReportsAnalyticsUseCase == null) return;

    _reportResource = Loading();
    notifyListeners();

    final result = await getReportsAnalyticsUseCase!.execute(userPin: userPin, startDate: startDate, endDate: endDate);
    _reportResource = result;
    if (result is Success) {
      _reportData = result.data;
    }
    notifyListeners();
  }

  Future<Resource<String>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? paymentType,
    double? upiAmount,
    double? cashAmount,
  }) async {
    if (updateOrderStatusUseCase == null) return Error(ServerFailure('UseCase not initialized'));

    String statusStr = newStatus.name;
    if (newStatus == OrderStatus.cancelled) {
      statusStr = 'cancelled';
    }

    final result = await updateOrderStatusUseCase!.execute(
      orderId: orderId,
      status: statusStr,
      paymentType: paymentType,
      upiAmount: upiAmount,
      cashAmount: cashAmount,
    );

    if (result is Success) {
      if (newStatus == OrderStatus.dispatched) {
        _orders.removeWhere((o) => o.id == orderId);
      } else {
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = _updateModelStatus(_orders[index], newStatus, paymentType: paymentType, upiAmount: upiAmount, cashAmount: cashAmount);
        }
      }

      final allIndex = _allOrders.indexWhere((o) => o.id == orderId);
      if (allIndex != -1) {
        _allOrders[allIndex] = _updateModelStatus(_allOrders[allIndex], newStatus, paymentType: paymentType, upiAmount: upiAmount, cashAmount: cashAmount);
      }

      _statusChangedOrderId = orderId;
      notifyListeners();

      // Reset pulse animation after it plays
      Future.delayed(const Duration(milliseconds: 800), () {
        _statusChangedOrderId = null;
        notifyListeners();
      });

      // Silent background refresh to update dashboard counts
      fetchDashboard(isRealtime: false);
    }
    return result;
  }

  Future<Resource<void>> deleteOrders({required String startDate, required String endDate}) async {
    if (deleteOrdersUseCase == null) return Error(ServerFailure('UseCase not initialized'));
    final result = await deleteOrdersUseCase!.execute(startDate: startDate, endDate: endDate);
    return result;
  }

  Future<Resource<void>> forgotPin({required String oldPin, required String newPin}) async {
    if (forgotPinUseCase == null) return Error(ServerFailure('UseCase not initialized'));
    final result = await forgotPinUseCase!.execute(oldPin: oldPin, newPin: newPin);
    return result;
  }

  OrderModel _updateModelStatus(OrderModel order, OrderStatus newStatus, {String? paymentType, double? upiAmount, double? cashAmount}) {
    return OrderModel(
      id: order.id,
      tokenNumber: order.tokenNumber,
      orderType: order.orderType,
      customerName: order.customerName,
      customerMobile: order.customerMobile,
      items: order.items,
      totalAmount: order.totalAmount,
      subtotalAmount: order.subtotalAmount,
      gstAmount: order.gstAmount,
      cgstAmount: order.cgstAmount,
      sgstAmount: order.sgstAmount,
      createdAt: order.createdAt,
      status: newStatus,
      specialNote: order.specialNote,
      paymentType: paymentType ?? order.paymentType,
      upiAmount: upiAmount ?? order.upiAmount,
      cashAmount: cashAmount ?? order.cashAmount,
    );
  }
}
