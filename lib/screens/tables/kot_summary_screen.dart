import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/table_provider.dart';
import '../../models/table_model.dart';
import '../../core/utils/custom_snackbar.dart';

class KOTSummaryScreen extends StatelessWidget {
  final String tableId;

  const KOTSummaryScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context) {
    final tableProvider = Provider.of<TableProvider>(context);
    final tableIndex = tableProvider.tables.indexWhere((t) => t.id == tableId);
    if (tableIndex == -1) return Scaffold(body: Center(child: Text('kot.table_not_found'.tr())));
    final table = tableProvider.tables[tableIndex];
    final order = table.activeOrder;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text('kot.summary_t'.tr(namedArgs: {'n': table.tableNumber.toString()}))),
      body: order == null || order.items.isEmpty
          ? Center(child: Text('kot.cart_empty'.tr()))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _buildHeader(table),
                      SizedBox(height: 16.h),
                      _buildItemsList(context, table, order),
                      SizedBox(height: 16.h),
                      _addMoreItemsButton(context),
                    ],
                  ),
                ),
                _buildBottomSummary(context, table, order),
              ],
            ),
    );
  }

  Widget _buildHeader(TableModel table) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _headerInfo('kot.table'.tr(), 'T${table.tableNumber}'),
          _headerInfo('Order Type', 'Dine-In'),
          _headerInfo('Status', table.status.name.toUpperCase()),
        ],
      ),
    );
  }

  Widget _headerInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context, TableModel table, TableOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              'kot.ordered_items_n'.tr(namedArgs: {'n': '${order.items.length}'}),
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.grey[600], letterSpacing: 0.5),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.menuItem.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                          ),
                          if (item.variant != null)
                            Text(
                              item.variant!,
                              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                            ),
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12.sp, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _qtyBtn(Icons.remove, () {
                          Provider.of<TableProvider>(
                            context,
                            listen: false,
                          ).updateItemQuantity(table.id, item.menuItem.id, -1, variant: item.variant);
                        }),
                        Container(
                          width: 40.w,
                          alignment: Alignment.center,
                          child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        _qtyBtn(Icons.add, () {
                          Provider.of<TableProvider>(
                            context,
                            listen: false,
                          ).updateItemQuantity(table.id, item.menuItem.id, 1, variant: item.variant);
                        }),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(icon, size: 16.sp, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _addMoreItemsButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.add),
        label: Text('kot.add_more'.tr()),
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, TableModel table, TableOrder order) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'kot.payable'.tr(),
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Provider.of<TableProvider>(context, listen: false).updateStatus(table.id, TableStatus.billed);
                      Navigator.pop(context); // Summary
                      Navigator.pop(context); // Order entry
                      CustomSnackbar.show(context, message: 'kot.table_billed'.tr(namedArgs: {'n': table.tableNumber.toString()}), isError: false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text('kot.print_bill'.tr()),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Provider.of<TableProvider>(context, listen: false).clearOrder(table.id);
                      Navigator.pop(context);
                      Navigator.pop(context);
                      CustomSnackbar.show(context, message: 'kot.completed'.tr(), isError: false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(
                      'kot.settle_clear'.tr(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
