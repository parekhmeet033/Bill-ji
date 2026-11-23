import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../screens/orders/order_details_screen.dart';
import '../core/utils/kitchen_print.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/resource.dart';
import '../core/utils/custom_snackbar.dart';

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool showToken;
  final bool showDate;
  final bool showActionButton;
  final String? typeData;

  const OrderCard({
    super.key,
    required this.order,
    this.showToken = true,
    this.showDate = false,
    this.showActionButton = true,
    this.typeData,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isUpdating = ValueNotifier<bool>(false);


  @override
  void didUpdateWidget(OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.status != widget.order.status && _isUpdating.value) {
      _isUpdating.value = false;
    }
  }

  @override
  void dispose() {
    _isExpanded.dispose();
    _isUpdating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? AppColors.subtleShadow
            : null,
      ),
      child: Column(children: [_buildHeader(), _buildExpandedContent()]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showToken) ...[_buildTokenBadge(), SizedBox(width: 12.w)],
          _buildOrderInfo(),
          _buildActionSection(),
          SizedBox(width: 10.w),
          _buildExpandButton(),
        ],
      ),
    );
  }

  Widget _buildTokenBadge() {
    final statusColor = _getStatusColor();
    final bool isDineIn = widget.order.orderType?.toLowerCase() == 'dine_in';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isDineIn ? 'TABLE' : 'TOKEN',
          style: TextStyle(
            fontSize: 8.sp,
            fontWeight: FontWeight.bold,
            color: statusColor,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          height: 36.sp,
          width: 36.sp,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              widget.order.tokenNumber,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.running:
        return AppColors.statusBlue;
      case OrderStatus.completed:
        return AppColors.primaryGreen;
      case OrderStatus.dispatched:
        return AppColors.statusBlue; // Changed from deepNavy
      case OrderStatus.cancelled:
        return AppColors.errorRed;
      default:
        return AppColors.statusBlue;
    }
  }

  Widget _buildOrderInfo() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: widget.order),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.order.customerName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 2.h),
            if (widget.showDate) ...[
              Text(
                DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(widget.order.createdAt),
                style: TextStyle(color: AppColors.grey, fontSize: 11.sp),
              ),
              SizedBox(height: 2.h),
            ],
            Text(
              '${widget.order.items.length} Items • ₹${widget.order.totalAmount}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isExpanded,
      builder: (context, isExpanded, child) {
        return GestureDetector(
          onTap: () => _isExpanded.value = !isExpanded,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: isExpanded
                  ? AppColors.statusBlue
                  : Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isExpanded ? Colors.white : AppColors.statusBlue,
              size: 22.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isExpanded,
      builder: (context, isExpanded, child) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: !isExpanded
              ? const SizedBox(width: double.infinity, height: 0)
              : Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      SizedBox(height: 12.h),
                      _buildMobileRow(),
                      SizedBox(height: 6.h),
                      _buildDetailRow(
                        'Time',
                        DateFormat('hh:mm a').format(widget.order.createdAt),
                        Icons.access_time,
                      ),
                      if (widget.order.specialNote != null &&
                          widget.order.specialNote!.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(10.w),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note_alt_outlined,
                                    color: Colors.orange,
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'order.special_note'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.sp,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                widget.order.specialNote!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'order.order_items'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (widget.showActionButton)
                            _buildKitchenPrintButton(),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      ...widget.order.items.map(_buildItemRow),
                      SizedBox(height: 12.h),
                      const Divider(height: 1),
                      SizedBox(height: 10.h),
                      if (widget.order.gstAmount != null && widget.order.gstAmount! > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'order.subtotal'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            Text(
                              '₹${(widget.order.subtotalAmount ?? (widget.order.totalAmount - widget.order.gstAmount!)).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'order.gst_label'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            Text(
                              '₹${widget.order.gstAmount!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'order.total_amount'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            '₹${widget.order.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: AppColors.statusBlue,
                            ),
                          ),
                        ],
                      ),
                      // For a part payment, show how much was received via UPI
                      // and how much via cash.
                      if (widget.order.paymentType?.toLowerCase() == 'part_payment') ...[
                        SizedBox(height: 8.h),
                        _buildSplitRow('pay.upi_amount'.tr(), widget.order.upiAmount ?? 0),
                        SizedBox(height: 4.h),
                        _buildSplitRow('pay.cash_amount'.tr(), widget.order.cashAmount ?? 0),
                      ],
                      // Cancel is available for any active order that was placed
                      // by mistake — take-away or dine-in — until it is dispatched
                      // or already cancelled.
                      if (widget.order.status == OrderStatus.pending ||
                          widget.order.status == OrderStatus.running ||
                          widget.order.status == OrderStatus.completed) ...[
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _isUpdating,
                            builder: (context, isUpdating, child) {
                              return OutlinedButton.icon(
                                onPressed: isUpdating
                                    ? null
                                    : () => _showCancelDialog(context),
                                icon: Icon(Icons.cancel_outlined, size: 18.sp),
                                label: Text('order.cancel_order'.tr()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.errorRed,
                                  side: const BorderSide(
                                    color: AppColors.errorRed,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'order.cancel_order'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'order.cancel_confirm_whatsapp'.tr(namedArgs: {'name': widget.order.customerName}),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'common.dismiss'.tr(),
              style: TextStyle(
                color: AppColors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleCancel(false);
            },
            child: Text(
              'order.cancel_only'.tr(),
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleCancel(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            child: Text('order.cancel_notify'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel(bool notify) async {
    _isUpdating.value = true;
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final result = await provider.updateOrderStatus(
      widget.order.id,
      OrderStatus.cancelled,
    );

    if (mounted) _isUpdating.value = false;

    if (result is Success && notify) {
      _launchWhatsApp();
    }
  }

  Future<void> _launchWhatsApp({String? message}) async {
    final String phone = widget.order.customerMobile;
    final String finalMessage =
        message ??
        "Dear ${widget.order.customerName}, your order (Token: ${widget.order.tokenNumber}) has been cancelled. Sorry for the inconvenience.";

    // Clean the phone number (remove any non-numeric characters)
    final String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Assume India (+91) if 10 digits are provided without a country code
    final String finalPhone = cleanPhone.length == 10
        ? "91$cleanPhone"
        : cleanPhone;

    // Use https://wa.me/ for maximum compatibility
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$finalPhone?text=${Uri.encodeComponent(finalMessage)}",
    );

    try {
      // Direct launch with externalApplication mode is generally most reliable for WhatsApp
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try to launch anyway even if canLaunchUrl returns false
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'order.could_not_whatsapp'.tr(),
        );
      }
    }
  }

  Future<void> _launchDialer(String phone) async {
    final Uri dialerUrl = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(dialerUrl)) {
        await launchUrl(dialerUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomSnackbar.show(context, message: 'order.could_not_dialer'.tr());
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, message: 'order.error_dialer'.tr(namedArgs: {'e': '$e'}));
      }
    }
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone, color: Colors.green, size: 20.sp),
                ),
                title: Text(
                  'order.call_customer'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: Text(
                  widget.order.customerMobile,
                  style: TextStyle(fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchDialer(widget.order.customerMobile);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    "assets/images/wp.png",
                    width: 24.sp,
                    height: 24.sp,
                  ),
                ),
                title: Text(
                  'order.whatsapp_message'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: Text(
                  'order.send_ready_msg'.tr(),
                  style: TextStyle(fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchWhatsApp(
                    message:
                        "Dear ${widget.order.customerName}, your order (Token: ${widget.order.tokenNumber}) is ready. Thank you!",
                  );
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileRow() {
    return GestureDetector(
      onTap: () => _showContactOptions(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(
            Icons.phone_android_outlined,
            color: AppColors.statusBlue,
            size: 14.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            'common.mobile'.tr(),
            style: TextStyle(color: AppColors.grey, fontSize: 12.sp),
          ),
          const Spacer(),
          Text(
            widget.order.customerMobile,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.statusBlue,
              fontSize: 12.sp,
              decoration: TextDecoration.underline,
            ),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.open_in_new, color: AppColors.statusBlue, size: 14.sp),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    String formattedQuantity = '${item.quantity}x';
    if (item.unit?.toUpperCase() == 'KG') {
      double qty = double.tryParse(item.quantity) ?? 0;
      if (qty < 1) {
        formattedQuantity = '${(qty * 1000).toStringAsFixed(0)} gm';
      } else {
        formattedQuantity = '${qty.toStringAsFixed(2)} kg';
      }
    } else if (item.unit?.toLowerCase() == 'nos') {
      formattedQuantity = '${item.quantity} Nos';
    }
    // Plate items show just the quantity (no 'Plt' suffix).

    double totalAmount =
        item.total ?? (item.price * (double.tryParse(item.quantity) ?? 0));

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.statusBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              formattedQuantity,
              style: TextStyle(
                color: AppColors.statusBlue,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Text(
            '₹${totalAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  // One line of a part-payment breakdown, e.g. "UPI amount        ₹300.00".
  Widget _buildSplitRow(String label, double amount) {
    final color = Theme.of(context).textTheme.bodySmall?.color;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.payments_outlined, size: 12.sp, color: color),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(fontSize: 12.sp, color: color)),
          ],
        ),
        Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12.sp, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.statusBlue, size: 14.sp),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(color: AppColors.grey, fontSize: 12.sp),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  // The payment method is only meaningful once the order has actually been
  // paid: a take-away order is paid when it is dispatched, a dine-in order when
  // it is completed/settled. Direct (POS) orders carry a default 'cash' type
  // even while pending, so we must gate on the paid state, not just a non-null
  // payment type, to avoid showing a payment method before any was collected.
  bool get _isPaid {
    final type = widget.order.paymentType;
    if (type == null || type.isEmpty) return false;
    final bool isDineIn = widget.order.orderType?.toLowerCase() == 'dine_in';
    if (isDineIn) return widget.order.status == OrderStatus.completed;
    return widget.order.status == OrderStatus.dispatched;
  }

  Widget _buildActionSection() {
    final Color paymentColor = _getPaymentColor(widget.order.paymentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStatusBadge(),
        if (_isPaid) ...[
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: paymentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: paymentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payments_outlined, size: 10.sp, color: paymentColor),
                SizedBox(width: 4.w),
                Text(
                  _formatPaymentType(widget.order.paymentType!),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: paymentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.showActionButton &&
            widget.order.status != OrderStatus.dispatched) ...[
          SizedBox(height: 6.h),
          _buildActionButton(context),
        ],
      ],
    );
  }

  Color _getPaymentColor(String? type) {
    if (type == null) return AppColors.grey;
    switch (type.toLowerCase()) {
      case 'upi':
        return AppColors.statusBlue;
      case 'cash':
        return AppColors.primaryGreen;
      case 'part_payment':
        return Colors.orange;
      default:
        return AppColors.grey;
    }
  }

  String _formatPaymentType(String type) {
    switch (type.toLowerCase()) {
      case 'upi':
        return 'UPI';
      case 'cash':
        return 'Cash';
      case 'part_payment':
        return 'UPI/Cash';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  Widget _buildActionButton(BuildContext context) {
    String label = '';
    Color color = AppColors.statusBlue;
    OrderStatus nextStatus = OrderStatus.pending;

    switch (widget.order.status) {
      case OrderStatus.pending:
        label = 'order.action.start_preparing'.tr();
        color = Colors.orange;
        nextStatus = OrderStatus.running;
        break;
      case OrderStatus.running:
        label = 'order.action.mark_ready'.tr();
        color = AppColors.statusBlue;
        nextStatus = OrderStatus.completed;
        break;
      case OrderStatus.completed:
        label = 'order.action.dispatched'.tr();
        color = AppColors.primaryGreen;
        nextStatus = OrderStatus.dispatched;
        break;
      case OrderStatus.cancelled:
        label = 'order.action.restore'.tr();
        color = Colors.blueGrey;
        nextStatus = OrderStatus.pending;
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      height: 28.h,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isUpdating,
        builder: (context, isUpdating, child) {
          return ElevatedButton(
            onPressed: isUpdating
                ? null
                : () async {
                    // Payment is captured when the order is placed, so
                    // advancing the status just updates it directly.
                    _isUpdating.value = true;
                    await Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    ).updateOrderStatus(widget.order.id, nextStatus);
                    if (mounted && _isUpdating.value) {
                      _isUpdating.value = false;
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              minimumSize: Size(80.w, 28.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
              textStyle: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: isUpdating
                ? SizedBox(
                    width: 12.sp,
                    height: 12.sp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(label),
          );
        },
      ),
    );
  }

  // Compact button placed next to the "Order Items" title, so the user
  // only sees/uses it once the tile is expanded (no extra full-width row).
  Widget _buildKitchenPrintButton() {
    return SizedBox(
      height: 24.h,
      child: OutlinedButton.icon(
        onPressed: _printKitchenTicket,
        icon: Icon(Icons.print_outlined, size: 12.sp),
        label: Text(
          'order.kitchen_print'.tr(),
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.statusBlue,
          side: BorderSide(color: AppColors.statusBlue.withValues(alpha: 0.5)),
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          minimumSize: Size(0, 24.h),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
      ),
    );
  }

  Future<void> _printKitchenTicket() {
    return KitchenPrint.printTicket(
      context,
      trackingKey: KitchenPrint.orderKey(widget.order.id),
      tokenNumber: widget.order.tokenNumber,
      items: widget.order.items,
      note: widget.order.specialNote,
      orderType: widget.order.orderType,
      customerName: widget.order.customerName,
      customerMobile: widget.order.customerMobile,
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;

    switch (widget.order.status) {
      case OrderStatus.pending:
        color = Colors.orange;
        label = 'order.status.pending'.tr();
        break;
      case OrderStatus.running:
        color = AppColors.statusBlue;
        label = 'order.status.cooking'.tr();
        break;
      case OrderStatus.completed:
        color = AppColors.primaryGreen;
        label = widget.typeData == 'Floor' ? 'order.status.completed'.tr() : 'order.status.packed'.tr();
        break;
      case OrderStatus.dispatched:
        color = AppColors.statusBlue; // Changed from deepNavy
        label = 'order.status.dispatched'.tr();
        break;
      case OrderStatus.cancelled:
        color = AppColors.errorRed;
        label = 'order.status.cancelled'.tr();
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
