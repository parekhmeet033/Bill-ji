import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../core/utils/resource.dart';
import 'order_provider.dart';

class ItemSaleAnalysis {
  final String name;
  final double quantity;
  final double revenue;
  final String unit;
  ItemSaleAnalysis({required this.name, required this.quantity, required this.revenue, required this.unit});
}

class ItemAnalysisProvider extends ChangeNotifier {
  List<ItemSaleAnalysis> _allStats = [];
  List<ItemSaleAnalysis> _topPerformers = [];
  List<ItemSaleAnalysis> _slowMoving = [];
  
  bool _isLoading = false;
  String _selectedFilter = 'This Month';
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalRevenue = 0;
  double _totalQuantity = 0;
  
  double _fetchProgress = 0;
  String _loadingMessage = '';

  // Getters
  List<ItemSaleAnalysis> get topPerformers => _topPerformers;
  List<ItemSaleAnalysis> get slowMoving => _slowMoving;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double get totalRevenue => _totalRevenue;
  double get totalQuantity => _totalQuantity;
  double get fetchProgress => _fetchProgress;
  String get loadingMessage => _loadingMessage;

  void setFilter(String filter, OrderProvider orderProvider) {
    _selectedFilter = filter;
    final now = DateTime.now();
    
    switch (filter) {
      case 'Today':
        _startDate = now;
        _endDate = now;
        break;
      case 'Yesterday':
        _startDate = now.subtract(const Duration(days: 1));
        _endDate = now.subtract(const Duration(days: 1));
        break;
      case 'This Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'Custom':
        // Wait for user to select range
        return;
    }
    fetchAndProcessData(orderProvider);
  }

  void setCustomRange(DateTime start, DateTime end, OrderProvider orderProvider) {
    _selectedFilter = 'Custom';
    _startDate = start;
    _endDate = end;
    fetchAndProcessData(orderProvider);
  }

  Future<void> fetchAndProcessData(OrderProvider orderProvider) async {
    if (_startDate == null || _endDate == null) return;

    _isLoading = true;
    _fetchProgress = 0;
    _loadingMessage = 'Starting data fetch...';
    notifyListeners();

    final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);

    try {
      List<OrderModel> allOrders = [];
      int currentPage = 1;
      int totalPages = 1;

      // Fetch all pages for the date range
      do {
        _loadingMessage = 'Fetching orders... (Page $currentPage)';
        if (totalPages > 1) {
          _fetchProgress = currentPage / totalPages;
        }
        notifyListeners();

        final result = await orderProvider.getOrdersListUseCase!.execute(
          status: 'All',
          orderType: 'All',
          search: '',
          startDate: startStr,
          endDate: endStr,
          page: currentPage,
        );

        if (result is Success) {
          final paginatedData = result.data!;
          allOrders.addAll(paginatedData.data);
          totalPages = paginatedData.pagination?.lastPage ?? 1;
          currentPage++;
        } else {
          break;
        }
      } while (currentPage <= totalPages);

      _loadingMessage = 'Processing data...';
      _fetchProgress = 1.0;
      notifyListeners();
      
      _processOrders(allOrders);
    } catch (e) {
      debugPrint('Error fetching analysis data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processOrders(List<OrderModel> orders) {
    final Map<String, Map<String, dynamic>> aggregation = {};
    _totalRevenue = 0;
    _totalQuantity = 0;

    for (var order in orders) {
      if (order.status == OrderStatus.cancelled) continue;
      
      for (var item in order.items) {
        final name = item.name;
        final qty = double.tryParse(item.quantity) ?? 0;
        final rev = item.total ?? (item.price * qty);
        final unit = item.unit ?? 'NOS';

        if (!aggregation.containsKey(name)) {
          aggregation[name] = {'qty': 0.0, 'rev': 0.0, 'unit': unit};
        }

        aggregation[name]!['qty'] = (aggregation[name]!['qty'] as double) + qty;
        aggregation[name]!['rev'] = (aggregation[name]!['rev'] as double) + rev;
        
        _totalRevenue += rev;
        _totalQuantity += qty;
      }
    }

    _allStats = aggregation.entries.map((e) => ItemSaleAnalysis(
      name: e.key,
      quantity: e.value['qty'] as double,
      revenue: e.value['rev'] as double,
      unit: e.value['unit'] as String,
    )).toList();

    // Sort by quantity descending
    _allStats.sort((a, b) => b.quantity.compareTo(a.quantity));

    // Top Performers (Top 10 or all if less)
    _topPerformers = _allStats.take(15).toList();

    // Slow Moving (Bottom 10, items with quantity > 0)
    if (_allStats.length > 15) {
      _slowMoving = _allStats.reversed.take(10).toList();
    } else {
      _slowMoving = [];
    }
  }
}
