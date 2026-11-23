import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/table_order_provider.dart';
import '../../providers/table_provider.dart';
import '../../providers/tables_provider.dart';
import '../../models/table_model.dart';
import 'table_order_screen.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tablesProvider = context.watch<TablesProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('tables.title'.tr()),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => _showAddTableDialog(context),
            tooltip: 'tables.add_table'.tr(),
          ),
        ],
      ),
      body: Consumer2<TableProvider, TableOrderProvider>(
        builder: (context, provider, orderProvider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          var tables = provider.tables;
          // Count active local orders from TableOrderProvider as occupied
          int activeLocalOrders = tables.where((t) => orderProvider.isTableActive(t.id)).length;

          final availableCount = tables
              .where((t) => t.status == TableStatus.available && !orderProvider.isTableActive(t.id))
              .length;
          final occupiedCount = tables.where((t) => t.status == TableStatus.occupied).length + activeLocalOrders;
          final billedCount = tables.where((t) => t.status == TableStatus.billed).length;

          if (tablesProvider.filter != null) {
            tables = tables.where((t) {
              if (tablesProvider.filter == TableStatus.occupied) {
                return t.status == TableStatus.occupied || orderProvider.isTableActive(t.id);
              }
              if (tablesProvider.filter == TableStatus.available) {
                return t.status == TableStatus.available && !orderProvider.isTableActive(t.id);
              }
              return t.status == tablesProvider.filter;
            }).toList();
          }

          return Column(
            children: [
              _buildSummaryHeader(context, tablesProvider, availableCount, occupiedCount, billedCount),
              Expanded(
                child: provider.tables.isEmpty
                    ? _buildEmptyState(context)
                    : GridView.builder(
                        padding: EdgeInsets.all(16.w),
                        // On tablet, a fixed 3-column grid leaves large empty
                        // cards in landscape (very wide) and forces awkward
                        // narrow cards in portrait. A max-extent delegate
                        // picks the column count from the available width
                        // instead, so it adapts to both orientations.
                        // Phones keep the original fixed 3-column grid.
                        gridDelegate: Responsive.isTablet(context)
                            ? SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 160.w,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                                childAspectRatio: 0.9,
                              )
                            : SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                                childAspectRatio: 0.9,
                              ),
                        itemCount: tables.length,
                        itemBuilder: (context, index) => _buildTableCard(context, tables[index], orderProvider),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, TablesProvider provider, int available, int occupied, int billed) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryBox(provider, 'tables.available'.tr(), available, Colors.green, TableStatus.available),
          _summaryBox(provider, 'tables.occupied'.tr(), occupied, AppColors.primaryBlue, TableStatus.occupied),
          _summaryBox(provider, 'tables.billed'.tr(), billed, Colors.orange, TableStatus.billed),
        ],
      ),
    );
  }

  Widget _summaryBox(TablesProvider provider, String label, int count, Color color, TableStatus status) {
    final isSelected = provider.filter == status;
    return GestureDetector(
      onTap: () => provider.setFilter(status),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isSelected ? color : Colors.transparent),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, TableModel table, TableOrderProvider orderProvider) {
    final theme = Theme.of(context);
    final bool hasActiveLocalOrder = orderProvider.isTableActive(table.id);

    Color statusColor;
    if (hasActiveLocalOrder || table.status == TableStatus.occupied) {
      statusColor = AppColors.primaryBlue;
    } else if (table.status == TableStatus.billed) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => TableOrderScreen(tableId: table.id)));
      },
      onLongPress: () => _showTableOptions(context, table),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.tableNumber.replaceAll(RegExp(r'[Tt]'), ''),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: statusColor),
            ),
            SizedBox(height: 4.h),
            if (hasActiveLocalOrder)
              Text(
                'tables.occupied'.tr().toUpperCase(),
                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, color: statusColor.withOpacity(0.8)),
              )
            else if (table.isOccupied)
              Text(
                '₹${table.activeOrder!.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              )
            else
              Text(
                table.status.name.toUpperCase(),
                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, color: statusColor.withOpacity(0.8)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_outlined, size: 64.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text('tables.no_tables'.tr(), style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('tables.add_table'.tr()),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'tables.table_number'.tr(), hintText: 'tables.hint_count'.tr()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Provider.of<TableProvider>(context, listen: false).addTable(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
            ),
            child: Text('common.add'.tr()),
          ),
        ],
      ),
    );
  }

  void _showTableOptions(BuildContext context, TableModel table) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('tables.edit_table_number'.tr()),
              onTap: () {
                Navigator.pop(context);
                _showEditTableDialog(context, table);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('tables.delete_table'.tr(), style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Provider.of<TableProvider>(context, listen: false).deleteTable(table.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTableDialog(BuildContext context, TableModel table) {
    final controller = TextEditingController(text: table.tableNumber);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('tables.edit_table'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'tables.table_number'.tr()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Provider.of<TableProvider>(context, listen: false).editTable(table.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
            ),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }
}
