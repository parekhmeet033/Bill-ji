import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../providers/orders_list_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import '../../widgets/responsive_paired_list.dart';
import '../../presentation/widgets/api_widgets.dart';
import '../../core/utils/resource.dart';

class OrdersListScreen extends StatefulWidget {
  final String typeData;

  const OrdersListScreen(this.typeData, {super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final ordersListProvider = Provider.of<OrdersListProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    ordersListProvider.init(widget.typeData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ordersListProvider.fetchOrders(orderProvider);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final ordersListProvider = Provider.of<OrdersListProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (orderProvider.allOrdersResource is Success && orderProvider.pagination != null) {
        if (ordersListProvider.currentPage < orderProvider.pagination!.lastPage) {
          ordersListProvider.setCurrentPage(ordersListProvider.currentPage + 1);
          ordersListProvider.fetchOrders(orderProvider, isRefresh: false);
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate, OrdersListProvider ordersListProvider, OrderProvider orderProvider) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? ordersListProvider.startDate : ordersListProvider.endDate) ?? today,
      firstDate: isStartDate ? DateTime(2020) : (ordersListProvider.startDate ?? DateTime(2020)),
      lastDate: today,
    );
    if (picked != null) {
      if (isStartDate) {
        ordersListProvider.setStartDate(picked);
      } else {
        ordersListProvider.setEndDate(picked);
      }
      ordersListProvider.fetchOrders(orderProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersListProvider = context.watch<OrdersListProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('order.all_orders'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(ordersListProvider, orderProvider),
          _buildOrderTypeTabs(ordersListProvider, orderProvider),
          _buildStatusTabs(ordersListProvider, orderProvider),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, provider, child) {
                final resource = provider.allOrdersResource;

                if (resource is Loading && provider.allOrders.isEmpty) {
                  return const LoadingWidget();
                }

                if (resource is Error && provider.allOrders.isEmpty) {
                  return ApiErrorWidget(
                    message: resource.failure?.message ?? 'Failed to load orders',
                    onRetry: () => ordersListProvider.fetchOrders(orderProvider),
                  );
                }

                final orders = provider.allOrders;

                if (orders.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () => ordersListProvider.fetchOrders(orderProvider),
                  child: ResponsivePairedList<OrderModel>(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    spacing: 12,
                    items: orders,
                    trailing: resource is Loading
                        ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                    )
                        : null,
                    itemBuilder: (context, order) => OrderCard(
                      order: order,
                      showToken: true,
                      showDate: true,
                      showActionButton: order.status == OrderStatus.cancelled,
                      typeData: widget.typeData,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_outlined, size: 40.sp, color: AppColors.primaryBlue.withValues(alpha: 0.6)),
            ),
            SizedBox(height: 16.h),
            Text(
              'order.no_orders_found'.tr(),
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color),
            ),
            SizedBox(height: 6.h),
            Text(
              'order.try_adjusting'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(OrdersListProvider ordersListProvider, OrderProvider orderProvider) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
      ),
      child: Column(
        children: [
          TextField(
            controller: ordersListProvider.searchController,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'order.search_hint'.tr(),
              hintStyle: TextStyle(fontSize: 13.sp, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue, size: 20.sp),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
            ),
            onChanged: (value) {
              ordersListProvider.fetchOrders(orderProvider);
            },
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: ordersListProvider.startDate == null ? 'Start Date' : DateFormat('yyyy-MM-dd').format(ordersListProvider.startDate!),
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context, true, ordersListProvider, orderProvider),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildDateField(
                  label: ordersListProvider.endDate == null ? 'End Date' : DateFormat('yyyy-MM-dd').format(ordersListProvider.endDate!),
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context, false, ordersListProvider, orderProvider),
                  isEnabled: ordersListProvider.startDate != null,
                ),
              ),
              if (ordersListProvider.startDate != null || ordersListProvider.endDate != null) ...[
                SizedBox(width: 8.w),
                _buildRoundIconButton(
                  icon: Icons.clear_all,
                  color: Colors.red,
                  onTap: () {
                    ordersListProvider.clearDates();
                    ordersListProvider.fetchOrders(orderProvider);
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(9.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 18.sp, color: color),
      ),
    );
  }

  Widget _buildOrderTypeTabs(OrdersListProvider ordersListProvider, OrderProvider orderProvider) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order.order_category'.tr(),
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.grey, letterSpacing: 0.8),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 48.h,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                _buildTypeToggleItem(ordersListProvider, orderProvider, 'All', Icons.list_alt_rounded),
                _buildTypeToggleItem(ordersListProvider, orderProvider, 'Takeaway', Icons.shopping_bag_outlined),
                _buildTypeToggleItem(ordersListProvider, orderProvider, 'Dinein', Icons.table_restaurant_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggleItem(OrdersListProvider ordersListProvider, OrderProvider orderProvider, String type, IconData icon) {
    final isSelected = ordersListProvider.selectedOrderType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            ordersListProvider.setSelectedOrderType(type);
            ordersListProvider.fetchOrders(orderProvider);
          }
        },
        child: AnimatedContainer(
          height: 48.h,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp, color: isSelected ? Colors.white : AppColors.grey),
              SizedBox(width: 6.w),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.grey,
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs(OrdersListProvider ordersListProvider, OrderProvider orderProvider) {
    List<String> statuses;
    if (ordersListProvider.selectedOrderType == 'Takeaway') {
      statuses = ['All', 'Pending', 'Running', 'Completed', 'Cancelled', 'Dispatched'];
    } else if (ordersListProvider.selectedOrderType == 'Dinein') {
      statuses = ['All', 'Pending', 'Completed'];
    } else {
      statuses = ['All', 'Pending', 'Running', 'Completed', 'Cancelled', 'Dispatched'];
    }

    return Container(
      height: 54.h,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.08))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = ordersListProvider.selectedStatus == status;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  ordersListProvider.setSelectedStatus(status);
                  ordersListProvider.fetchOrders(orderProvider);
                }
              },
              selectedColor: AppColors.primaryBlue,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              elevation: 0,
              pressElevation: 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateField({required String label, required IconData icon, required VoidCallback onTap, bool isEnabled = true}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isEnabled ? theme.scaffoldBackgroundColor : theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15.sp, color: isEnabled ? AppColors.primaryBlue.withValues(alpha: 0.7) : AppColors.grey.withValues(alpha: 0.3)),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}