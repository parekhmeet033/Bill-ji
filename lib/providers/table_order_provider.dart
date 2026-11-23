import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/usecases/save_table_order_usecase.dart';
import '../domain/usecases/create_pos_order_usecase.dart';
import '../domain/usecases/get_pos_draft_usecase.dart';
import '../domain/usecases/save_pos_draft_usecase.dart';
import '../domain/usecases/clear_pos_draft_usecase.dart';
import '../models/order_model.dart';
import '../models/table_product_list_model.dart';
import '../models/pending_table_model.dart';
import '../core/utils/resource.dart';
import '../core/error/failures.dart';
import '../core/error/error_handler.dart';
import '../core/utils/kitchen_print.dart';

class TableOrderProvider extends ChangeNotifier {
  final SaveTableOrderUseCase? saveTableOrderUseCase;
  final CreatePosOrderUseCase? createPosOrderUseCase;
  final GetPosDraftUseCase? getPosDraftUseCase;
  final SavePosDraftUseCase? savePosDraftUseCase;
  final ClearPosDraftUseCase? clearPosDraftUseCase;

  static const String posSessionId = 'POS';

  final Map<String, Map<int, double>> _tableCarts = {};
  final Map<String, Set<int>> _removedItems = {};
  final Map<String, String> _customerNames = {};
  final Map<String, String> _customerMobiles = {};
  final Map<String, String> _orderNotes = {};
  final Map<String, Map<int, String>> _selectedVariants = {};
  final Map<String, Map<int, double>> _variantPrices = {};

  // Each customized add of an item is recorded here as its own instance
  // ({note, qty, unitPrice}) so the bill/kitchen copy can show it as a separate
  // line instead of merging every add of the same product into one group. The
  // unit price is absolute (base + sub-category charge), so a reloaded order
  // can restore instances straight from the server rows without the base price.
  final Map<String, Map<int, List<({String note, double qty, double unitPrice})>>> _customInstances = {};

  List<({String note, double qty, double unitPrice})> getCustomInstances(String tableId, int productId) =>
      _customInstances[_sanitizeId(tableId)]?[productId] ?? const [];

  /// Whether this item was added with a sub-category customization. Such items
  /// can't be deleted from the order (their delete controls are hidden).
  bool itemHasCustomization(String tableId, int productId) =>
      _customInstances[_sanitizeId(tableId)]?[productId]?.isNotEmpty ?? false;

  int? _selectedCategoryId;
  String _searchText = '';
  bool _isLoading = false;
  Timer? _autoSyncTimer;

  TableOrderProvider({this.saveTableOrderUseCase, this.createPosOrderUseCase, this.getPosDraftUseCase, this.savePosDraftUseCase, this.clearPosDraftUseCase});

  String _sanitizeId(String id) => id.replaceAll(RegExp(r'[Tt]'), '');

  Map<int, double> getCart(String tableId) => _tableCarts[_sanitizeId(tableId)] ?? {};

  Set<int> getRemovedItems(String tableId) => _removedItems[_sanitizeId(tableId)] ?? {};

  String getCustomerName(String tableId) => _customerNames[_sanitizeId(tableId)] ?? '';

  String getCustomerMobile(String tableId) => _customerMobiles[_sanitizeId(tableId)] ?? '';

  String getOrderNote(String tableId) => _orderNotes[_sanitizeId(tableId)] ?? '';

  String? getSelectedVariant(String tableId, int productId) {
    final sId = _sanitizeId(tableId);
    return _selectedVariants[sId]?[productId];
  }

  double getVariantPrice(String tableId, int productId) {
    final sId = _sanitizeId(tableId);
    return _variantPrices[sId]?[productId] ?? 0.0;
  }

  void setSelectedVariant(
    String tableId,
    int productId,
    String? variant, {
    double additionalPrice = 0.0,
  }) {
    final sId = _sanitizeId(tableId);
    if (!_selectedVariants.containsKey(sId)) {
      _selectedVariants[sId] = {};
      _variantPrices[sId] = {};
    }
    if (variant == null || variant.trim().isEmpty) {
      _selectedVariants[sId]!.remove(productId);
      _variantPrices[sId]!.remove(productId);
    } else {
      _selectedVariants[sId]![productId] = variant;
      _variantPrices[sId]![productId] = additionalPrice;
    }
    notifyListeners();
  }

  /// Adds one more unit of a customizable item, accumulating this instance's
  /// subcategory charge and note onto the line. The stored per-unit add-on is
  /// kept as the line average (total add-on / qty), so the existing per-unit
  /// [TableProductModel.calculateTotal] still yields the correct line total
  /// (base*qty + sum of every instance's subcategory charge).
  void addCustomizedUnit(
    String tableId,
    int productId, {
    String? note,
    double instanceCharge = 0.0,
    List<TableProductModel>? allProducts
  }) {
    final sId = _sanitizeId(tableId);
    _tableCarts.putIfAbsent(sId, () => {});
    _selectedVariants.putIfAbsent(sId, () => {});
    _variantPrices.putIfAbsent(sId, () => {});

    final double oldQty = _tableCarts[sId]![productId] ?? 0;
    final double oldAddPrice = _variantPrices[sId]![productId] ?? 0;
    final double newQty = oldQty + 1;
    // Total add-on so far + this instance's charge, spread over the new qty.
    final double newAddPrice = ((oldAddPrice * oldQty) + instanceCharge) / newQty;

    final String? existing = _selectedVariants[sId]![productId];
    final String trimmed = note?.trim() ?? '';
    String? combined;
    if (trimmed.isNotEmpty) {
      combined = (existing != null && existing.trim().isNotEmpty) ? '$existing, $trimmed' : trimmed;
    } else {
      combined = existing;
    }

    if (combined != null && combined.trim().isNotEmpty) {
      _selectedVariants[sId]![productId] = combined;
      _variantPrices[sId]![productId] = newAddPrice;
    }

    // Record this single add as its own instance so it prints as a separate
    // line on the bill (see [_enumerateLines]). Store the absolute unit price
    // (base + this instance's charge) so it survives a reload.
    double base = 0;
    if (allProducts != null) {
      try {
        base = double.tryParse(allProducts.firstWhere((p) => p.id == productId).price) ?? 0;
      } catch (_) {}
    }
    _customInstances.putIfAbsent(sId, () => {});
    _customInstances[sId]!.putIfAbsent(productId, () => []);
    _customInstances[sId]![productId]!.add((note: trimmed, qty: 1, unitPrice: base + instanceCharge));

    _tableCarts[sId]![productId] = newQty;
    _removedItems[sId]?.remove(productId);
    notifyListeners();

    if (allProducts != null && allProducts.isNotEmpty) {
      _triggerAutoSync(sId, allProducts);
    }
  }

  bool get isLoading => _isLoading;

  int? get selectedCategoryId => _selectedCategoryId;

  String get searchText => _searchText;

  void updateQuantity(
    String tableId,
    int productId,
    double quantity, {
    bool isExplicitRemove = false,
    List<TableProductModel>? allProducts,
  }) {
    final sId = _sanitizeId(tableId);
    if (!_tableCarts.containsKey(sId)) {
      _tableCarts[sId] = {};
    }

    if (quantity <= 0) {
      // An item that was added with a sub-category customization can't be
      // deleted from the order; ignore any request to remove it entirely.
      if (_customInstances[sId]?[productId]?.isNotEmpty ?? false) {
        return;
      }
      _tableCarts[sId]!.remove(productId);
      _selectedVariants[sId]?.remove(productId);
      _variantPrices[sId]?.remove(productId);
      _customInstances[sId]?.remove(productId);
      if (isExplicitRemove) {
        if (!_removedItems.containsKey(sId)) {
          _removedItems[sId] = {};
        }
        _removedItems[sId]!.add(productId);
      }
    } else {
      _tableCarts[sId]![productId] = quantity;
      _removedItems[sId]?.remove(productId);
      // Keep the recorded instances aligned with the quantity: decrementing
      // drops (or shrinks) the most recently added instance(s) from the end.
      final insts = _customInstances[sId]?[productId];
      if (insts != null) {
        double total = insts.fold(0.0, (s, i) => s + i.qty);
        double excess = total - quantity;
        while (excess > 0 && insts.isNotEmpty) {
          final last = insts.last;
          if (last.qty <= excess) {
            excess -= last.qty;
            insts.removeLast();
          } else {
            insts[insts.length - 1] = (note: last.note, qty: last.qty - excess, unitPrice: last.unitPrice);
            excess = 0;
          }
        }
      }
    }
    notifyListeners();

    if (allProducts != null && allProducts.isNotEmpty) {
      _triggerAutoSync(sId, allProducts);
    }
  }

  void _triggerAutoSync(String tableId, List<TableProductModel> allProducts) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(const Duration(milliseconds: 500), () {
      if (_sanitizeId(tableId) == posSessionId) {
        // Auto-save the POS take-away cart as a server-side draft so it isn't
        // lost if the app/device restarts before the order is placed.
        savePosOrder(allProducts: allProducts, draft: true);
      } else {
        saveOrder(
          tableId: tableId,
          status: 'pending',
          allProducts: allProducts,
        );
      }
    });
  }

  void setCustomerDetails(
    String tableId, {
    String? name,
    String? mobile,
    String? note,
    List<TableProductModel>? allProducts,
  }) {
    final sId = _sanitizeId(tableId);
    if (name != null) _customerNames[sId] = name;
    if (mobile != null) _customerMobiles[sId] = mobile;
    if (note != null) _orderNotes[sId] = note;
    notifyListeners();

    if (allProducts != null && allProducts.isNotEmpty) {
      _triggerAutoSync(sId, allProducts);
    }
  }

  bool isTableActive(String tableId) {
    final sId = _sanitizeId(tableId);
    return (_tableCarts.containsKey(sId) && _tableCarts[sId]!.isNotEmpty) ||
        (_removedItems.containsKey(sId) && _removedItems[sId]!.isNotEmpty);
  }

  void setCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearch(String text) {
    _searchText = text;
    notifyListeners();
  }

  void clearCart(String tableId) {
    final sId = _sanitizeId(tableId);
    _tableCarts.remove(sId);
    _removedItems.remove(sId);
    _customerNames.remove(sId);
    _customerMobiles.remove(sId);
    _orderNotes.remove(sId);
    _selectedVariants.remove(sId);
    _variantPrices.remove(sId);
    _customInstances.remove(sId);
    KitchenPrint.resetTable(sId);
    notifyListeners();
  }

  void initializeFromPendingTable(PendingTableModel pendingData) {
    final String tableId = _sanitizeId(pendingData.tableNo.toString());

    debugPrint('Initializing Table $tableId from API with ${pendingData.items.length} items');

    _tableCarts[tableId] = {};
    _removedItems[tableId] = {};
    _selectedVariants[tableId] = {};
    _variantPrices[tableId] = {};
    _customInstances[tableId] = {};

    _customerNames[tableId] = pendingData.customerName;
    _customerMobiles[tableId] = pendingData.customerMobile;
    _orderNotes[tableId] = pendingData.orderNote;

    for (var item in pendingData.items) {
      final int pid = item.productId;
      // Accumulate quantity so multiple server rows for the same product (one
      // per customized instance) aren't lost by overwriting each other.
      _tableCarts[tableId]![pid] = (_tableCarts[tableId]![pid] ?? 0) + item.qty;

      // Restore each customized/noted row as its own instance (absolute unit
      // price from the server) so the sub-category and its charge survive the
      // reload and show as a separate line.
      final String note = item.note?.trim() ?? '';
      if (note.isNotEmpty) {
        _customInstances[tableId]!.putIfAbsent(pid, () => []);
        _customInstances[tableId]![pid]!.add((note: note, qty: item.qty, unitPrice: item.price));

        // Also keep the combined sub-category note on the grouped line so the
        // dine-in cart (_cartInner), which reads getSelectedVariant, still
        // shows the sub-category after a restart.
        final String? existing = _selectedVariants[tableId]![pid];
        _selectedVariants[tableId]![pid] =
            (existing != null && existing.trim().isNotEmpty) ? '$existing, $note' : note;
      }
    }

    notifyListeners();
  }

  double _round2(double v) => double.parse(v.toStringAsFixed(2));

  /// Expands the cart into the individual bill lines. A customizable item that
  /// was added with sub-categories becomes one line per instance (base price +
  /// that instance's charge); any remaining plain quantity becomes a single
  /// line, and non-customized items stay as one line as before. Both the UI
  /// totals ([computeBillTotals]) and the saved/printed items are built from
  /// this, so they always agree.
  List<({TableProductModel product, double qty, double unitPrice, double lineTotal, String? note})>
      _enumerateLines(String rawId, List<TableProductModel> allProducts) {
    final sId = _sanitizeId(rawId);
    final cart = getCart(sId);
    final lines = <({TableProductModel product, double qty, double unitPrice, double lineTotal, String? note})>[];
    for (final e in cart.entries) {
      try {
        final product = allProducts.firstWhere((x) => x.id == e.key);
        final double qty = e.value;
        final double base = double.tryParse(product.price) ?? 0;
        final instances = _customInstances[sId]?[product.id] ?? const <({String note, double qty, double unitPrice})>[];

        if (instances.isNotEmpty) {
          double instQty = 0;
          for (final inst in instances) {
            instQty += inst.qty;
            final double unitPrice = _round2(inst.unitPrice);
            final String? note = inst.note.trim().isEmpty ? null : inst.note.trim();
            lines.add((product: product, qty: inst.qty, unitPrice: unitPrice, lineTotal: _round2(unitPrice * inst.qty), note: note));
          }
          // Quantity beyond the recorded instances (e.g. a plain "+") as one line.
          final double remainder = qty - instQty;
          if (remainder > 0) {
            lines.add((
              product: product,
              qty: remainder,
              unitPrice: base,
              lineTotal: product.calculateTotal(remainder, optionsPrice: 0),
              note: null,
            ));
          }
        } else {
          final double addPrice = getVariantPrice(sId, product.id);
          lines.add((
            product: product,
            qty: qty,
            unitPrice: base + addPrice,
            lineTotal: product.calculateTotal(qty, optionsPrice: addPrice),
            note: getSelectedVariant(sId, product.id),
          ));
        }
      } catch (_) {}
    }
    return lines;
  }

  /// The cart as individual display lines (one per customized instance, plus
  /// one per plain item), so a cart view can show each sub-category separately
  /// just like the bill and the order-details sheet.
  List<({TableProductModel product, double qty, double unitPrice, double lineTotal, String? note})>
      buildDisplayLines(String tableId, List<TableProductModel> allProducts) =>
          _enumerateLines(tableId, allProducts);

  /// Total amount for one product's grouped cart line (sum of every instance +
  /// any plain remainder). Uses the stored instance prices, so it stays correct
  /// after a restart even though the averaged per-unit add-on isn't restored.
  double productLineTotal(String tableId, int productId, List<TableProductModel> allProducts) {
    double sum = 0;
    for (final l in _enumerateLines(tableId, allProducts)) {
      if (l.product.id == productId) sum += l.lineTotal;
    }
    return _round2(sum);
  }

  /// Builds the kitchen-ticket items for the current cart, expanding each
  /// customized instance into its own entry (same split as the bill) so the
  /// kitchen copy shows every sub-category separately.
  List<OrderItem> buildKitchenItems(String tableId, List<TableProductModel> allProducts) {
    return _enumerateLines(tableId, allProducts)
        .map((l) => OrderItem(
              productId: l.product.id,
              name: l.product.name,
              quantity: KitchenPrint.formatQty(l.qty),
              price: l.unitPrice,
              total: l.lineTotal,
              unit: l.product.unit,
              note: l.note,
            ))
        .toList();
  }

  /// GST-aware bill totals for the current cart, matching the backend's
  /// calculation (GST added on top of the line totals when the shop has GST
  /// enabled and the product is GST-applicable).
  ({double subtotal, double gst, double cgst, double sgst, double grandTotal})
      computeBillTotals(String sessionId, List<TableProductModel> allProducts, {required bool gstEnabled}) {
    final sId = _sanitizeId(sessionId);
    double subtotal = 0;
    double gst = 0;
    for (final line in _enumerateLines(sId, allProducts)) {
      subtotal += line.lineTotal;
      // Round GST per line (matches saveOrder and the backend) so the shown
      // total equals the printed receipt total.
      if (gstEnabled && line.product.gstApplicable) gst += _round2(line.lineTotal * (line.product.gstRate / 100.0));
    }
    subtotal = _round2(subtotal);
    gst = _round2(gst);
    final double half = _round2(gst / 2);
    return (subtotal: subtotal, gst: gst, cgst: half, sgst: half, grandTotal: _round2(subtotal + gst));
  }

  Future<Resource<OrderModel>> saveOrder({
    required String tableId,
    required String status,
    required List<TableProductModel> allProducts,
    String? paymentType,
    double? upiAmount,
    double? cashAmount,
    bool gstEnabled = false,
  }) async {
    final sId = _sanitizeId(tableId);
    if (saveTableOrderUseCase == null) return Error(ServerFailure('Service not initialized'));

    _isLoading = true;
    notifyListeners();

    try {
      final removedItems = getRemovedItems(sId).toList();

      double gstTotal = 0;
      final List<Map<String, dynamic>> itemsJson = [];
      final List<OrderItem> itemsModel = [];

      // Each customized instance is its own line (see [_enumerateLines]).
      for (final line in _enumerateLines(sId, allProducts)) {
        final product = line.product;
        final bool itemGst = gstEnabled && product.gstApplicable;
        final double lineGst = itemGst ? _round2(line.lineTotal * (product.gstRate / 100.0)) : 0.0;
        gstTotal += lineGst;

        itemsJson.add({
          "product_id": product.id,
          "product_name": product.name,
          "price": line.unitPrice,
          "qty": line.qty,
          "unit": product.unit ?? "NOS",
          "total": line.lineTotal,
          "note": line.note,
        });

        itemsModel.add(OrderItem(
          name: product.name,
          quantity: line.qty.toString(),
          price: line.unitPrice,
          total: line.lineTotal,
          unit: product.unit,
          note: line.note,
          gstApplicable: itemGst,
          gstRate: product.gstRate,
          gstAmount: lineGst,
          taxableAmount: line.lineTotal,
        ));
      }

      final double subtotal = _round2(itemsModel.fold(0.0, (s, i) => s + (i.total ?? 0)));
      gstTotal = _round2(gstTotal);
      final double grandTotal = _round2(subtotal + gstTotal);

      final Map<String, dynamic> requestData = {
        "table_no": int.tryParse(sId) ?? 0,
        "customer_name": getCustomerName(sId),
        "customer_mobile": getCustomerMobile(sId),
        "order_note": getOrderNote(sId),
        "total_amount": grandTotal,
        "order_status": status,
        "items": itemsJson,
        "remove_items": removedItems,
        "payment_type": paymentType,
        "upi_amount": upiAmount,
        "cash_amount": cashAmount,
      };

      final result = await saveTableOrderUseCase!(requestData);

      final OrderModel constructedOrder = OrderModel(
        id: '',
        tokenNumber: sId,
        customerName: getCustomerName(sId),
        customerMobile: getCustomerMobile(sId),
        items: itemsModel,
        totalAmount: grandTotal,
        subtotalAmount: subtotal,
        gstAmount: gstTotal > 0 ? gstTotal : null,
        cgstAmount: gstTotal > 0 ? _round2(gstTotal / 2) : null,
        sgstAmount: gstTotal > 0 ? _round2(gstTotal / 2) : null,
        createdAt: DateTime.now(),
        status: status == 'completed' ? OrderStatus.completed : OrderStatus.pending,
        specialNote: getOrderNote(sId),
        orderType: 'dine_in',
        paymentType: paymentType,
      );

      if (result is Success && status == 'completed') {
        clearCart(sId);
      } else if (result is Success) {
        _removedItems[sId]?.clear();
      }

      _isLoading = false;
      notifyListeners();

      if (result is Success) {
        return Success(constructedOrder);
      } else {
        return Error((result as Error).failure!);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return Error(ErrorHandler.handle(e));
    }
  }

  Future<Resource<OrderModel>> savePosOrder({
    required List<TableProductModel> allProducts,
    String sessionId = posSessionId,
    String? paymentType,
    double? upiAmount,
    double? cashAmount,
    bool gstEnabled = false,
    bool draft = false,
  }) async {
    if (createPosOrderUseCase == null) return Error(ServerFailure('Service not initialized'));

    final cart = getCart(sessionId);
    if (cart.isEmpty) {
      // A draft auto-save with nothing in the cart is a no-op (don't error or
      // touch the server); placing an order still requires at least one item.
      if (draft) return Success(OrderModel(id: '', tokenNumber: '', customerName: '', customerMobile: '', items: const [], totalAmount: 0, createdAt: DateTime.now(), status: OrderStatus.pending, orderType: 'takeaway'));
      return Error(ServerFailure('Please add at least one item'));
    }

    // A draft auto-save runs quietly in the background — don't flip the global
    // loading flag or it would spin the UI on every keystroke.
    if (!draft) {
      // Placing the order: cancel any pending draft auto-save so it can't fire
      // afterwards and resurrect a draft from the (soon-cleared) cart.
      _autoSyncTimer?.cancel();
      _isLoading = true;
      notifyListeners();
    }

    try {

      double gstTotal = 0;
      final List<Map<String, dynamic>> itemsJson = [];
      final List<OrderItem> itemsModel = [];

      // Each customized instance is its own line (see [_enumerateLines]).
      for (final line in _enumerateLines(sessionId, allProducts)) {
        final product = line.product;
        final bool itemGst = gstEnabled && product.gstApplicable;
        final double lineGst = itemGst ? _round2(line.lineTotal * (product.gstRate / 100.0)) : 0.0;
        gstTotal += lineGst;

        itemsJson.add({
          "product_id": product.id,
          "product_name": product.name,
          "price": line.unitPrice,
          "qty": line.qty,
          "unit": product.unit ?? "NOS",
          "total": line.lineTotal,
          "note": line.note,
        });

        itemsModel.add(OrderItem(
          name: product.name,
          quantity: line.qty.toString(),
          price: line.unitPrice,
          total: line.lineTotal,
          unit: product.unit,
          note: line.note,
          gstApplicable: itemGst,
          gstRate: product.gstRate,
          gstAmount: lineGst,
          taxableAmount: line.lineTotal,
        ));
      }

      final double subtotal = _round2(itemsModel.fold(0.0, (s, i) => s + (i.total ?? 0)));
      gstTotal = _round2(gstTotal);
      final double grandTotal = _round2(subtotal + gstTotal);

      final Map<String, dynamic> requestData = {
        "customer_name": getCustomerName(sessionId),
        "customer_mobile": getCustomerMobile(sessionId),
        "special_note": getOrderNote(sessionId),
        "total_amount": grandTotal,
        // 'draft' keeps this as the auto-saved in-progress cart; placing the
        // order omits it (defaults to 'pending' server-side).
        if (draft) "order_status": "draft",
        if (paymentType != null) "payment_type": paymentType,
        if (upiAmount != null) "upi_amount": upiAmount,
        if (cashAmount != null) "cash_amount": cashAmount,
        "items": itemsJson,
      };

      // A draft goes to its own endpoint (never creates a placed order); a
      // backend without draft support simply fails this call, which is ignored.
      // Placing the order goes through the normal POS endpoint, which returns
      // the server order id/token so the bill can be printed locally with dedup.
      bool success;
      Failure? failure;
      String serverOrderId = '';
      String serverToken = '';
      if (draft) {
        if (savePosDraftUseCase == null) {
          success = false;
          failure = ServerFailure('Draft not supported');
        } else {
          final r = await savePosDraftUseCase!(requestData);
          success = r is Success;
          if (r is Error) failure = r.failure;
        }
      } else {
        final r = await createPosOrderUseCase!(requestData);
        success = r is Success;
        if (r is Success<Map<String, dynamic>>) {
          serverOrderId = r.data?['order_id']?.toString() ?? '';
          serverToken = r.data?['token_no']?.toString() ?? '';
        } else if (r is Error) {
          failure = r.failure;
        }
      }

      final OrderModel constructedOrder = OrderModel(
        id: serverOrderId,
        tokenNumber: serverToken,
        customerName: getCustomerName(sessionId),
        customerMobile: getCustomerMobile(sessionId),
        items: itemsModel,
        totalAmount: grandTotal,
        subtotalAmount: subtotal,
        gstAmount: gstTotal > 0 ? gstTotal : null,
        cgstAmount: gstTotal > 0 ? _round2(gstTotal / 2) : null,
        sgstAmount: gstTotal > 0 ? _round2(gstTotal / 2) : null,
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
        specialNote: getOrderNote(sessionId),
        orderType: 'takeaway',
      );

      // A draft keeps the cart intact (it's the in-progress order). Only a
      // placed order clears the POS session.
      if (success && !draft) {
        clearCart(sessionId);
        _customerNames.remove(sessionId);
        _customerMobiles.remove(sessionId);
        _orderNotes.remove(sessionId);
        _selectedVariants.remove(sessionId);
        _variantPrices.remove(sessionId);
      }

      if (!draft) {
        _isLoading = false;
        notifyListeners();
      }

      if (success) {
        return Success(constructedOrder);
      } else {
        return Error(failure ?? ServerFailure('Failed to place order'));
      }
    } catch (e) {
      if (!draft) {
        _isLoading = false;
        notifyListeners();
      }
      return Error(ErrorHandler.handle(e));
    }
  }

  /// Restores the server-side POS take-away draft (auto-saved cart) into the
  /// local POS session, so an in-progress order survives an app/device restart.
  /// Skips if there is already a local POS cart (don't clobber fresh input).
  Future<void> restorePosDraft() async {
    if (getPosDraftUseCase == null) return;
    if (getCart(posSessionId).isNotEmpty) return;
    final result = await getPosDraftUseCase!();
    if (result is Success<OrderModel?> && result.data != null) {
      _loadDraftIntoPos(result.data!);
    }
  }

  /// Discards the server-side POS draft (used when the POS order is cancelled)
  /// so it isn't restored on the next launch.
  Future<void> cancelPosDraft() async {
    if (clearPosDraftUseCase == null) return;
    try {
      await clearPosDraftUseCase!();
    } catch (_) {}
  }

  void _loadDraftIntoPos(OrderModel order) {
    const sId = posSessionId;
    _tableCarts[sId] = {};
    _removedItems[sId] = {};
    _selectedVariants[sId] = {};
    _variantPrices[sId] = {};
    _customInstances[sId] = {};
    _customerNames[sId] = order.customerName;
    _customerMobiles[sId] = order.customerMobile;
    _orderNotes[sId] = order.specialNote ?? '';

    for (final item in order.items) {
      final int? pid = item.productId;
      if (pid == null) continue;
      final double q = double.tryParse(item.quantity) ?? 0;
      if (q <= 0) continue;
      _tableCarts[sId]![pid] = (_tableCarts[sId]![pid] ?? 0) + q;
      final String note = item.note?.trim() ?? '';
      if (note.isNotEmpty) {
        _customInstances[sId]!.putIfAbsent(pid, () => []);
        _customInstances[sId]![pid]!.add((note: note, qty: q, unitPrice: item.price));
      }
    }
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategoryId = null;
    _searchText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
