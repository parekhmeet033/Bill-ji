import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/utils/resource.dart';
import 'order_provider.dart';

class ReportsProvider extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'All';
  String _selectedOrderType = 'All';
  int _currentPage = 1;
  bool _isSearching = false;
  bool _isPinVerified = false;
  bool _isVerifying = false;
  bool _obscureVerifyPin = true;

  // Getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get selectedStatus => _selectedStatus;
  String get selectedOrderType => _selectedOrderType;
  int get currentPage => _currentPage;
  bool get isSearching => _isSearching;
  bool get isPinVerified => _isPinVerified;
  bool get isVerifying => _isVerifying;
  bool get obscureVerifyPin => _obscureVerifyPin;

  void toggleSearching() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      searchController.clear();
    }
    notifyListeners();
  }

  void toggleObscurePin() {
    _obscureVerifyPin = !_obscureVerifyPin;
    notifyListeners();
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

  void resetVerification() {
    _isPinVerified = false;
    _isVerifying = false;
    pinController.clear();
    notifyListeners();
  }

  Future<void> verifyPin(OrderProvider orderProvider) async {
    if (pinController.text.length != 6) {
      return;
    }

    _isVerifying = true;
    notifyListeners();

    await orderProvider.fetchReports(userPin: pinController.text);

    _isVerifying = false;
    if (orderProvider.reportResource is Success) {
      _isPinVerified = true;
    }
    notifyListeners();
  }

  Future<void> fetchData(OrderProvider orderProvider, {bool isRefresh = true}) async {
    if (!_isPinVerified) return;
    if (isRefresh) _currentPage = 1;

    final startDateStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '';
    final endDateStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '';

    // Fetch reports summary, scoped to the selected date range when set.
    orderProvider.fetchReports(userPin: pinController.text, startDate: startDateStr, endDate: endDateStr);

    String orderTypeParam = 'All';
    if (_selectedOrderType == 'Takeaway') {
      orderTypeParam = 'take_away';
    } else if (_selectedOrderType == 'Dinein') {
      orderTypeParam = 'dine_in';
    }

    // Fetch filtered order history
    await orderProvider.fetchOrdersList(
      status: _selectedStatus,
      orderType: orderTypeParam,
      search: searchController.text,
      startDate: startDateStr,
      endDate: endDateStr,
      page: _currentPage,
      isRefresh: isRefresh,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    pinController.dispose();
    super.dispose();
  }
}
