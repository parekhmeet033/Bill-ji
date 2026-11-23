import 'package:flutter/material.dart';
import 'table_order_provider.dart';

class TableOrderViewProvider extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController upiAmountController = TextEditingController();
  final TextEditingController cashAmountController = TextEditingController();
  // Cash tendered by the customer (to compute "Return to Customer").
  final TextEditingController cashReceivedController = TextEditingController();

  String? _loadingAction;
  String? get loadingAction => _loadingAction;

  // Canonical payment type: 'cash' | 'upi' | 'part_payment' (never the display label,
  // so it stays correct across languages and maps directly to the backend value).
  String _paymentType = 'cash';
  String get paymentType => _paymentType;

  bool _isSynced = false;
  bool get isSynced => _isSynced;

  // Whether the right-side cart panel is open (landscape only).
  bool _cartOpen = false;
  bool get cartOpen => _cartOpen;

  // Last seen distinct-item count, used to auto-open the panel when an item is
  // added. Updated without notifying so it can be read/written during build.
  int _lastItemCount = 0;
  int get lastItemCount => _lastItemCount;
  void updateLastItemCount(int value) => _lastItemCount = value;

  // The screen's build() runs init on every rebuild (e.g. when the keyboard
  // opens), but init resets controllers and panel state, which would wipe what
  // the user is typing and close the cart. This guards init to the first build
  // per table entry; it resets when a different table is opened.
  String? _initedTableId;
  bool isInitedFor(String tableId) => _initedTableId == tableId;
  void markInitedFor(String tableId) => _initedTableId = tableId;
  // Call when the table is finalized (completed/cancelled) so re-opening it
  // starts fresh instead of keeping the previous order's details.
  void resetInit() => _initedTableId = null;

  void init(String tableId, TableOrderProvider orderProvider, {bool alreadySynced = false}) {
    _initedTableId = tableId;
    nameController.text = orderProvider.getCustomerName(tableId);
    mobileController.text = orderProvider.getCustomerMobile(tableId);
    noteController.text = orderProvider.getOrderNote(tableId);
    searchController.clear();
    upiAmountController.clear();
    cashAmountController.clear();
    cashReceivedController.clear();
    _loadingAction = null;
    _paymentType = 'cash';
    _isSynced = alreadySynced;
    _cartOpen = false;
    _lastItemCount = 0;
  }

  void setCartOpen(bool value) {
    if (_cartOpen == value) return;
    _cartOpen = value;
    notifyListeners();
  }

  void toggleCart() => setCartOpen(!_cartOpen);

  void setPaymentType(String type) {
    _paymentType = type;
    notifyListeners();
  }

  void setSynced(bool value) {
    _isSynced = value;
    notifyListeners();
  }

  void setLoadingAction(String? action) {
    _loadingAction = action;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    mobileController.dispose();
    noteController.dispose();
    upiAmountController.dispose();
    cashAmountController.dispose();
    cashReceivedController.dispose();
    super.dispose();
  }
}
