import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import 'package:lineless/core/services/printer_service.dart';
import '../../providers/order_details_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/custom_snackbar.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/primary_button.dart';
import '../settings/printer_settings_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  Future<void> _printReceipt(BuildContext context, OrderDetailsProvider detailsProvider, OrderProvider orderProvider) async {
    final printer = PrinterService();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (printer.device == null && !printer.isEthernet) {
      CustomSnackbar.show(context, message: 'order.no_printer'.tr());
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()));
      return;
    }
    final bool isEthernet = printer.isEthernet;
    final bool isBluetoothOn = !isEthernet && await PrintBluetoothThermal.bluetoothEnabled;
    final bool hasDevice = printer.device != null;

    final bool shouldShowDialog = isEthernet || (hasDevice && isBluetoothOn);

    detailsProvider.setPrinting(true);

    if (shouldShowDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              children: [
                const CircularProgressIndicator(color: AppColors.primaryBlue),
                SizedBox(width: 20.w),
                Text(
                  "Printing Receipt...",
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final success = await printer.printReceipt(
        order,
        userName: orderProvider.dashboardData?.userName,
        // Print the GST number whenever one is entered, even if GST is off.
        gstin: settings.gstin.trim().isNotEmpty ? settings.gstin : null,
      );
      
      if (context.mounted && shouldShowDialog) {
        Navigator.pop(context);
      }

      if (success) {
        CustomSnackbar.show(context, message: 'order.receipt_sent'.tr(), isError: false);
      } else if (shouldShowDialog) {
        CustomSnackbar.show(context, message: 'order.print_failed'.tr());
      } else if (!isEthernet && !isBluetoothOn) {
        CustomSnackbar.show(context, message: 'order.bluetooth_off'.tr());
      }
    } catch (e) {
      if (context.mounted && shouldShowDialog) Navigator.pop(context);
      debugPrint('Print error: $e');
    } finally {
      detailsProvider.setPrinting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsProvider = context.watch<OrderDetailsProvider>();
    final orderProvider = context.watch<OrderProvider>();

    Future.microtask(() => detailsProvider.setPrinting(false));

    final bool hasGst = (order.gstAmount != null && order.gstAmount! > 0);
    final double subtotal = order.subtotalAmount ?? (order.totalAmount - (order.gstAmount ?? 0));
    final double gstAmt = order.gstAmount ?? 0.0;
    final double cgstAmt = order.cgstAmount ?? (gstAmt / 2);
    final double sgstAmt = order.sgstAmount ?? (gstAmt / 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('${order.orderType == 'dine_in' ? 'Table No : ' : 'Token No : '} ${order.tokenNumber}'),
        actions: [
          detailsProvider.isPrinting
              ? Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: SizedBox(
                    width: 20.sp,
                    height: 20.sp,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.print_rounded),
                  tooltip: 'order.print_receipt'.tr(),
                  onPressed: () => _printReceipt(context, detailsProvider, orderProvider),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: Theme.of(context).brightness == Brightness.light ? AppColors.subtleShadow : null,
              ),
              child: Column(
                children: [
                  _buildDetailRow('Customer', order.customerName, Icons.person_outline, context),
                  Divider(height: 24.h),
                  _buildDetailRow('Mobile', order.customerMobile, Icons.phone_android_outlined, context),
                  Divider(height: 24.h),
                  _buildDetailRow('Time', '10:30 AM', Icons.access_time, context),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'order.ordered_items'.tr(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 12.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => Divider(height: 20.h),
              itemBuilder: (context, index) => _buildItemRow(order.items[index], context),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: AppColors.deepNavy, borderRadius: BorderRadius.circular(16.r)),
              child: Column(
                children: [
                  if (hasGst) ...[
                    _buildCostRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}', isBold: false),
                    SizedBox(height: 8.h),
                    _buildCostRow('CGST', '₹${cgstAmt.toStringAsFixed(2)}', isBold: false),
                    SizedBox(height: 8.h),
                    _buildCostRow('SGST', '₹${sgstAmt.toStringAsFixed(2)}', isBold: false),
                    const Divider(color: Colors.white24, height: 20),
                  ],
                  _buildCostRow('Grand Total', '₹${order.totalAmount.toStringAsFixed(2)}', isBold: true),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            if (order.status == OrderStatus.pending)
              PrimaryButton(
                label: 'order.start_running'.tr(),
                onPressed: () {
                  Provider.of<OrderProvider>(context, listen: false).updateOrderStatus(order.id, OrderStatus.running);
                  Navigator.pop(context);
                },
              )
            else if (order.status == OrderStatus.running)
              PrimaryButton(
                label: 'order.mark_completed'.tr(),
                color: AppColors.primaryGreen,
                onPressed: () {
                  Provider.of<OrderProvider>(context, listen: false).updateOrderStatus(order.id, OrderStatus.completed);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white70,
            fontSize: isBold ? 16.sp : 13.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isBold ? 18.sp : 13.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(OrderItem item, BuildContext context) {
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

    double totalAmount = item.total ?? (item.price * (double.tryParse(item.quantity) ?? 0));

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4.r)),
          child: Text(
            formattedQuantity,
            style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              if (item.gstApplicable && item.gstRate != null && item.gstRate! > 0)
                Text(
                  'order.gst_rate'.tr(namedArgs: {'rate': item.gstRate!.toStringAsFixed(0)}),
                  style: TextStyle(fontSize: 10.sp, color: AppColors.grey),
                ),
            ],
          ),
        ),
        Text(
          '₹${totalAmount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 18.sp),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(color: AppColors.grey, fontSize: 13.sp),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13.sp),
        ),
      ],
    );
  }
}
