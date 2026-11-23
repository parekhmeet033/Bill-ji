import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/utils/resource.dart';
import 'order_provider.dart';

class OrdersListProvider extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'All';
  String _selectedOrderType = 'All';
  int _currentPage = 1;

  // Getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get selectedStatus => _selectedStatus;
  String get selectedOrderType => _selectedOrderType;
  int get currentPage => _currentPage;

  void init(String typeData) {
    _selectedOrderType = typeData == 'Floor' ? 'Dinein' : 'Takeaway';
    _selectedStatus = 'All';
    _currentPage = 1;
    _startDate = null;
    _endDate = null;
    searchController.clear();
  }

  void setStartDate(DateTime? date) {
    _startDate = date;
    if (_endDate != null && _startDate != null && _startDate!.isAfter(_endDate!)) {
      _endDate = null;
    }
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSelectedOrderType(String type) {
    if (_selectedOrderType != type) {
      _selectedOrderType = type;
      _selectedStatus = 'All';
      notifyListeners();
    }
  }

  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void clearDates() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  Future<void> fetchOrders(OrderProvider orderProvider, {bool isRefresh = true}) async {
    if (isRefresh) _currentPage = 1;

    final startDateStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '';
    final endDateStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '';

    String orderTypeParam = 'All';
    if (_selectedOrderType == 'Takeaway') {
      orderTypeParam = 'take_away';
    } else if (_selectedOrderType == 'Dinein') {
      orderTypeParam = 'dine_in';
    }

    await orderProvider.fetchOrdersList(
      status: _selectedStatus,
      orderType: orderTypeParam,
      search: searchController.text,
      startDate: startDateStr,
      endDate: endDateStr,
      page: _currentPage,
      isRefresh: isRefresh,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
