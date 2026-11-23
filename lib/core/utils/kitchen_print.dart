import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/order_model.dart';
import '../services/printer_service.dart';
import '../theme/app_colors.dart';
import 'custom_snackbar.dart';

/// Single entry point for kitchen printing. Every "Kitchen Print" button goes
/// through [printTicket] so the printer check, ticket contents (including the
/// order note) and user feedback stay the same on every screen.
class KitchenPrint {
  KitchenPrint._();

  static final Map<String, _SentRecord> _sent = {};

  static String tableKey(String tableId) => 'table-${tableId.replaceAll(RegExp(r'[^0-9]'), '')}';

  static String orderKey(String orderId) => 'order-$orderId';

  static void resetTable(String tableId) => _sent.remove(tableKey(tableId));

  static Future<void> printTicket(
    BuildContext context, {
    required String trackingKey,
    required String tokenNumber,
    required List<OrderItem> items,
    required String? note,
    String? orderType = 'dine_in',
    String? sessionId,
    DateTime? orderCreatedAt,
    String? customerName,
    String? customerMobile,
  }) async {
    if (_inProgress) {
      CustomSnackbar.show(context, message: 'kprint.in_progress'.tr());
      return;
    }
    _inProgress = true;
    try {
      await _printTicket(
        context,
        trackingKey: trackingKey,
        tokenNumber: tokenNumber,
        items: items,
        note: note,
        orderType: orderType,
        sessionId: sessionId,
        orderCreatedAt: orderCreatedAt,
        customerName: customerName,
        customerMobile: customerMobile,
      );
    } finally {
      _inProgress = false;
    }
  }

  static bool _inProgress = false;

  static Future<void> _printTicket(
    BuildContext context, {
    required String trackingKey,
    required String tokenNumber,
    required List<OrderItem> items,
    required String? note,
    required String? orderType,
    required String? sessionId,
    DateTime? orderCreatedAt,
    String? customerName,
    String? customerMobile,
  }) async {
    final orderedItems = items.where((i) => _qty(i) > 0).toList();
    if (orderedItems.isEmpty) {
      CustomSnackbar.show(context, message: 'kprint.no_items'.tr());
      return;
    }

    final printer = PrinterService();
    if (printer.device == null && !printer.isEthernet) {
      CustomSnackbar.show(context, message: 'kprint.no_printer'.tr());
      return;
    }

    final kitchenItems = <OrderItem>[];
    final nonKitchenItems = <OrderItem>[];
    for (final item in orderedItems) {
      (printer.isKitchenItem(productId: item.productId, name: item.name) ? kitchenItems : nonKitchenItems).add(item);
    }
    if (kitchenItems.isEmpty) {
      CustomSnackbar.show(context, message: 'kprint.none_kitchen'.tr());
      return;
    }

    var record = _sent[trackingKey];
    if (record != null && sessionId != null && record.sessionId != null && record.sessionId != sessionId) {
      _sent.remove(trackingKey);
      record = null;
    }
    final sent = record?.quantities ?? const <String, double>{};

    final newItems = <OrderItem>[];
    final sentItems = <OrderItem>[];
    for (final item in kitchenItems) {
      final qty = _qty(item);
      final sentQty = sent[_itemKey(item)] ?? 0;
      final pending = _round(qty - sentQty);
      if (pending > 0) newItems.add(pending == qty ? item : _withQty(item, pending));
      if (sentQty > 0) sentItems.add(_withQty(item, sentQty < qty ? sentQty : qty));
    }

    final choice = await showDialog<_KitchenPrintChoice>(
      context: context,
      builder: (_) => _KitchenPrintDialog(
        newItems: newItems,
        allItems: kitchenItems,
        sentItems: sentItems,
        nonKitchenItems: nonKitchenItems,
        initialNote: note?.trim() ?? '',
      ),
    );
    if (choice == null || !context.mounted) return;

    final toPrint = (choice.reprintAll ? kitchenItems : newItems)
        .map((item) => _withNote(item, choice.itemNotes[_itemKey(item)]))
        .toList();
    if (toPrint.isEmpty) return;

    final trimmedNote = choice.note.trim();

    try {
      final success = await printer.printKitchenTicket(
        OrderModel(
          id: 'kitchen-${DateTime.now().millisecondsSinceEpoch}',
          tokenNumber: tokenNumber,
          customerName: customerName?.trim() ?? '',
          customerMobile: customerMobile?.trim() ?? '',
          items: toPrint,
          totalAmount: 0,
          createdAt: orderCreatedAt ?? DateTime.now(),
          status: OrderStatus.pending,
          specialNote: trimmedNote.isEmpty ? null : trimmedNote,
          orderType: orderType,
        ),
      );

      if (success) {
        final updated = Map<String, double>.from(sent);
        for (final item in kitchenItems) {
          final key = _itemKey(item);
          final qty = _qty(item);
          if (qty > (updated[key] ?? 0)) updated[key] = qty;
        }
        _sent[trackingKey] = _SentRecord(sessionId ?? record?.sessionId, updated);
      }

      if (context.mounted) {
        CustomSnackbar.show(
          context,
          message: success ? 'kprint.sent_success'.tr() : 'kprint.failed_conn'.tr(),
          isError: !success,
        );
      }
    } catch (_) {
      if (context.mounted) {
        CustomSnackbar.show(context, message: 'kprint.failed_retry'.tr());
      }
    }
  }

  static String formatQty(double qty) => qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

  static double _qty(OrderItem item) => double.tryParse(item.quantity.trim()) ?? 1;

  static double _round(double value) => double.parse(value.toStringAsFixed(3));

  // The note is part of the key so two adds of the same product with different
  // sub-categories stay separate on the kitchen copy (same split as the bill),
  // instead of collapsing onto one line with a single note.
  static String _itemKey(OrderItem item) {
    final base = item.productId != null ? 'id:${item.productId}' : 'name:${item.name.trim().toLowerCase()}|${item.unit ?? ''}';
    final note = item.note?.trim() ?? '';
    return note.isEmpty ? base : '$base|note:${note.toLowerCase()}';
  }

  static OrderItem _withQty(OrderItem item, double qty) => OrderItem(
    productId: item.productId,
    name: item.name,
    quantity: formatQty(qty),
    price: item.price,
    unit: item.unit,
    note: item.note,
  );

  static OrderItem _withNote(OrderItem item, String? note) {
    final trimmed = note?.trim();
    return OrderItem(
      productId: item.productId,
      name: item.name,
      quantity: item.quantity,
      price: item.price,
      total: item.total,
      unit: item.unit,
      note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
  }
}

class _SentRecord {
  final String? sessionId;
  final Map<String, double> quantities;

  _SentRecord(this.sessionId, this.quantities);
}

class _KitchenPrintChoice {
  final String note;
  final bool reprintAll;
  final Map<String, String> itemNotes;

  _KitchenPrintChoice(this.note, this.reprintAll, this.itemNotes);
}

class _KitchenPrintDialog extends StatefulWidget {
  final List<OrderItem> newItems;
  final List<OrderItem> allItems;
  final List<OrderItem> sentItems;
  final List<OrderItem> nonKitchenItems;
  final String initialNote;

  const _KitchenPrintDialog({
    required this.newItems,
    required this.allItems,
    required this.sentItems,
    required this.nonKitchenItems,
    required this.initialNote,
  });

  @override
  State<_KitchenPrintDialog> createState() => _KitchenPrintDialogState();
}

class _KitchenPrintDialogState extends State<_KitchenPrintDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialNote);
  bool _reprintAll = false;

  final Map<String, TextEditingController> _itemNotes = {};
  // The fixed sub-category text per item key. It can't be erased or removed
  // from the kitchen ticket; the user may only append an extra note to it.
  final Map<String, String> _lockedBaseNotes = {};
  String? _focusItemKey;

  @override
  void initState() {
    super.initState();
    for (final item in widget.allItems) {
      final note = item.note?.trim();
      if (note != null && note.isNotEmpty) {
        final key = KitchenPrint._itemKey(item);
        // Keep the sub-category as a fixed base; the editable controller holds
        // only the user's extra note (starts empty).
        _lockedBaseNotes[key] = note;
        _itemNotes[key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _itemNotes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItemNote(String key) {
    setState(() {
      _itemNotes[key] = TextEditingController();
      _focusItemKey = key;
    });
  }

  void _removeItemNote(String key) {
    final controller = _itemNotes.remove(key);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => controller?.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final toPrint = _reprintAll ? widget.allItems : widget.newItems;

    return AlertDialog(
      scrollable: true,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      title: Text('kprint.title'.tr()),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (toPrint.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'kprint.all_sent'.tr(),
                  style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                ),
              )
            else ...[
              Text(
                'kprint.to_print'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 4.h),
              for (final item in toPrint) _buildPrintItem(item),
            ],
            if (widget.sentItems.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _section('kprint.already_sent'.tr(), widget.sentItems, AppColors.grey),
              CheckboxListTile(
                value: _reprintAll,
                onChanged: (v) => setState(() => _reprintAll = v ?? false),
                title: Text('kprint.reprint_all'.tr(), style: TextStyle(fontSize: 12.sp)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
            if (widget.nonKitchenItems.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _section('kprint.not_printed'.tr(), widget.nonKitchenItems, AppColors.grey),
            ],
            SizedBox(height: 12.h),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'kprint.note_kitchen'.tr(),
                hintText: 'kprint.note_hint'.tr(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr())),
        ElevatedButton(
          onPressed: toPrint.isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  _KitchenPrintChoice(_controller.text, _reprintAll, {
                    for (final entry in _itemNotes.entries) entry.key: _composeNote(entry.key, entry.value.text),
                  }),
                ),
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text('kprint.print'.tr()),
        ),
      ],
    );
  }

  // Combines the fixed sub-category (if any) with the user's extra note so the
  // sub-category always stays on the ticket while an added note is appended.
  String _composeNote(String key, String extra) {
    final base = _lockedBaseNotes[key]?.trim() ?? '';
    final e = extra.trim();
    if (base.isEmpty) return e;
    if (e.isEmpty) return base;
    return '$base, $e';
  }

  Widget _buildPrintItem(OrderItem item) {
    final key = KitchenPrint._itemKey(item);
    final noteController = _itemNotes[key];
    final String? baseNote = _lockedBaseNotes[key];
    final bool isLocked = baseNote != null;

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _line(item),
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
              ),
              if (noteController == null)
                TextButton.icon(
                  onPressed: () => _addItemNote(key),
                  icon: Icon(Icons.edit_note, size: 16.sp),
                  label: Text('kprint.note'.tr(), style: TextStyle(fontSize: 11.sp)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    minimumSize: Size(0, 28.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          // Fixed sub-category line — always printed, cannot be erased.
          if (isLocked)
            Padding(
              padding: EdgeInsets.only(left: 12.w, top: 2.h),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 14.sp, color: AppColors.grey),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      baseNote,
                      style: TextStyle(fontSize: 12.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          // Editable note: the user's extra instructions for this item. For a
          // customized item this is appended to the sub-category; for a plain
          // item it is the whole note (and can be removed).
          if (noteController != null)
            Padding(
              padding: EdgeInsets.only(left: 12.w, top: 2.h),
              child: TextField(
                controller: noteController,
                autofocus: key == _focusItemKey,
                minLines: 1,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 12.sp),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: isLocked ? 'kprint.add_note'.tr() : 'kprint.note_for'.tr(namedArgs: {'name': item.name}),
                  prefixIcon: Icon(Icons.subdirectory_arrow_right, size: 16.sp, color: AppColors.grey),
                  prefixIconConstraints: BoxConstraints(minWidth: 24.w),
                  // A locked sub-category item keeps its editable note always
                  // visible (no remove button, since removing would hide the
                  // only way to add an instruction); plain notes stay removable.
                  suffixIcon: isLocked
                      ? null
                      : IconButton(
                          onPressed: () => _removeItemNote(key),
                          icon: Icon(Icons.close, size: 16.sp),
                          tooltip: 'kprint.remove_note'.tr(),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, List<OrderItem> items, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color),
        ),
        SizedBox(height: 4.h),
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Text(
              _line(item),
              style: TextStyle(fontSize: 12.sp, color: color),
            ),
          ),
      ],
    );
  }

  String _line(OrderItem item) {
    final qty = KitchenPrint.formatQty(KitchenPrint._qty(item));
    final unit = item.unit?.toUpperCase();
    final qtyText = (unit == null || unit == 'NOS' || unit == 'QTY') ? '${qty}x' : '$qty ${unit.toLowerCase()}';
    return '$qtyText  ${item.name}';
  }
}
