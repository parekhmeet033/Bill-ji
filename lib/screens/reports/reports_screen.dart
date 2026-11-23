import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/reports_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/utils/resource.dart';
import '../../presentation/widgets/api_widgets.dart';
import '../../widgets/order_card.dart';
import '../../widgets/responsive_paired_list.dart';
import '../../core/utils/custom_snackbar.dart';
import 'item_analysis_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _verifyPin(BuildContext context, ReportsProvider reportsProvider, OrderProvider orderProvider) async {
    if (reportsProvider.pinController.text.length != 6) {
      CustomSnackbar.show(context, message: 'reports.enter_pin_err'.tr());
      return;
    }

    await reportsProvider.verifyPin(orderProvider);

    if (context.mounted) {
      if (reportsProvider.isPinVerified) {
        reportsProvider.fetchData(orderProvider);
      } else {
        reportsProvider.pinController.clear();
        CustomSnackbar.show(context, message: (orderProvider.reportResource as Error).failure?.message ?? 'reports.invalid_pin'.tr());
      }
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isStartDate,
    ReportsProvider reportsProvider,
    OrderProvider orderProvider,
  ) async {
    if (!isStartDate && reportsProvider.startDate == null) {
      CustomSnackbar.show(context, message: 'reports.select_start_date'.tr());
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? reportsProvider.startDate : reportsProvider.endDate) ?? today,
      firstDate: isStartDate ? DateTime(2020) : reportsProvider.startDate!,
      lastDate: today,
    );

    if (picked != null) {
      if (isStartDate) {
        reportsProvider.setStartDate(picked);
      } else {
        reportsProvider.setEndDate(picked);
      }
      reportsProvider.fetchData(orderProvider);
    }
  }

  Future<void> _deleteRecords(BuildContext context, ReportsProvider reportsProvider, OrderProvider orderProvider) async {
    if (reportsProvider.startDate == null || reportsProvider.endDate == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('reports.delete_records'.tr()),
        content: Text(
          'Are you sure you want to delete all records from ${DateFormat('yyyy-MM-dd').format(reportsProvider.startDate!)} to ${DateFormat('yyyy-MM-dd').format(reportsProvider.endDate!)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final startDateStr = DateFormat('yyyy-MM-dd').format(reportsProvider.startDate!);
      final endDateStr = DateFormat('yyyy-MM-dd').format(reportsProvider.endDate!);

      final result = await orderProvider.deleteOrders(startDate: startDateStr, endDate: endDateStr);

      if (context.mounted) {
        if (result is Success) {
          CustomSnackbar.show(context, message: 'reports.records_deleted'.tr(), isError: false);
          reportsProvider.clearDates();
          reportsProvider.fetchData(orderProvider);
        } else {
          CustomSnackbar.show(context, message: (result as Error).failure?.message ?? 'reports.failed_delete_records'.tr());
        }
      }
    }
  }

  Future<void> _showChangePinDialog(BuildContext context, OrderProvider orderProvider) async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    bool obscureOld = true;
    bool obscureNew = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          // In landscape (especially on a tablet, where the keyboard can
          // take up a large share of the shorter screen height) the title
          // + two PIN fields + actions don't all fit in the space left
          // above the keyboard. `scrollable: true` wraps AlertDialog's
          // content in a SingleChildScrollView so it scrolls instead of
          // overflowing — a no-op visually whenever everything already
          // fits (portrait, phone, keyboard closed, etc.).
          scrollable: true,
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.security_update_good, color: AppColors.primaryBlue, size: 32.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'reports.change_security_pin'.tr(),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              Text(
                'reports.change_pin_desc'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
              SizedBox(height: 12.h),
            ],
          ),
          content: SizedBox(
            width: 320.w, // Fixed responsive width for the dialog content
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModernPinInput(
                    context,
                    controller: oldPinController,
                    label: 'reports.current_pin'.tr(),
                    obscure: obscureOld,
                    onToggleObscure: () => setDialogState(() => obscureOld = !obscureOld),
                    onStateChanged: () => setDialogState(() {}),
                  ),
                  SizedBox(height: 20.h),
                  _buildModernPinInput(
                    context,
                    controller: newPinController,
                    label: 'reports.new_pin'.tr(),
                    obscure: obscureNew,
                    onToggleObscure: () => setDialogState(() => obscureNew = !obscureNew),
                    onStateChanged: () => setDialogState(() {}),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        setDialogState(() => isSubmitting = true);
                        final result = await orderProvider.forgotPin(
                          oldPin: oldPinController.text,
                          newPin: newPinController.text,
                        );

                        if (context.mounted) {
                          setDialogState(() => isSubmitting = false);
                          if (result is Success) {
                            Navigator.pop(context);
                            CustomSnackbar.show(context, message: 'reports.pin_changed'.tr(), isError: false);
                          } else {
                            CustomSnackbar.show(context, message: (result as Error).failure?.message ?? 'reports.failed_change_pin'.tr());
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: isSubmitting
                  ? SizedBox(
                      height: 18.h,
                      width: 18.h,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'common.submit'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPinInput(
    BuildContext context, {
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? label,
    VoidCallback? onStateChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.grey),
              ),
              TextButton.icon(
                onPressed: onToggleObscure,
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16.sp),
                label: Text(obscure ? 'common.show'.tr() : 'common.hide'.tr(), style: TextStyle(fontSize: 11.sp)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: AppColors.primaryBlue),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        Stack(
          alignment: Alignment.center,
          children: [
            // Hidden TextField to capture input
            Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                onChanged: (v) {
                  if (onStateChanged != null) {
                    onStateChanged();
                  }
                },
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
            // Visible PIN Boxes
            IgnorePointer(
              child: Row(
                children: List.generate(11, (i) {
                  // Even indices are boxes, odd are spacers
                  if (i.isOdd) return SizedBox(width: 6.w);

                  final index = i ~/ 2;
                  bool isFilled = controller.text.length > index;
                  bool isFocused = controller.text.length == index;
                  String char = isFilled ? controller.text[index] : '';

                  return Expanded(
                    child: AspectRatio(
                      aspectRatio: 0.85, // Slightly taller than wide
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isFocused
                              ? AppColors.primaryBlue.withValues(alpha: 0.1)
                              : isFilled
                              ? AppColors.primaryBlue.withValues(alpha: 0.05)
                              : theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isFocused
                                ? AppColors.primaryBlue
                                : isFilled
                                ? AppColors.primaryBlue.withValues(alpha: 0.5)
                                : theme.dividerColor.withValues(alpha: 0.2),
                            width: isFocused ? 2.w : 1.2.w,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: isFilled
                            ? ZoomIn(
                                duration: const Duration(milliseconds: 250),
                                child: obscure
                                    ? Container(
                                        width: 10.w,
                                        height: 10.w,
                                        decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                      )
                                    : Text(
                                        char,
                                        style: TextStyle(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                              )
                            : isFocused
                            ? FadeIn(
                                animate: true,
                                duration: const Duration(milliseconds: 1000),
                                child: Container(width: 2.w, height: 22.h, color: AppColors.primaryBlue),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final orderProvider = context.watch<OrderProvider>();

    if (!reportsProvider.isPinVerified) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('reports.security_verification'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setTab(NavTab.home),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: ConstrainedBox(
              // On phones this is wider than the screen ever is, so it
              // never binds and the layout is byte-for-byte the same as
              // before. On tablets it stops the PIN boxes / button from
              // stretching edge-to-edge across the whole wide screen,
              // which is what made them look oversized.
              constraints: BoxConstraints(maxWidth: Responsive.isTablet(context) ? 420.w : double.infinity),
              child: Container(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 28.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: AppColors.subtleShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.lock_outline, size: 40.sp, color: AppColors.primaryBlue),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'reports.enter_pin'.tr(),
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'reports.pin_restricted'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
                    ),
                    SizedBox(height: 28.h),
                    ListenableBuilder(
                      listenable: reportsProvider.pinController,
                      builder: (context, child) {
                        return _buildModernPinInput(
                          context,
                          controller: reportsProvider.pinController,
                          obscure: reportsProvider.obscureVerifyPin,
                          onToggleObscure: () => reportsProvider.toggleObscurePin(),
                          onStateChanged: () {}, // Handled by ListenableBuilder
                        );
                      },
                    ),
                    SizedBox(height: 28.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: reportsProvider.isVerifying ? null : () => _verifyPin(context, reportsProvider, orderProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: reportsProvider.isVerifying
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'reports.verify_pin'.tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text('reports.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Provider.of<NavigationProvider>(
            context,
            listen: false,
          ).setTab(NavTab.home),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item Analysis
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ItemAnalysisScreen(),
                      ),
                    ),
                    icon: Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.blue.shade700,
                      size: 19,
                    ),
                    tooltip: 'reports.item_analysis'.tr(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),

                // Change PIN
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _showChangePinDialog(
                      context,
                      orderProvider,
                    ),
                    icon: Icon(
                      Icons.password_rounded,
                      color: Colors.orange.shade700,
                      size: 19,
                    ),
                    tooltip: 'reports.change_pin'.tr(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context, reportsProvider, orderProvider),
          _buildOrderTypeTabs(context, reportsProvider, orderProvider),
          _buildStatusTabs(context, reportsProvider, orderProvider),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, provider, child) {
                final reportResource = provider.reportResource;
                final orderResource = provider.allOrdersResource;

                if (reportResource is Loading && provider.reportData == null) {
                  return const LoadingWidget();
                }

                final data = provider.reportData;

                return RefreshIndicator(
                  onRefresh: () => reportsProvider.fetchData(orderProvider),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(14.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, 'reports.sales_overview'.tr(), Icons.insights_outlined),
                        SizedBox(height: 10.h),
                        // When a date range is selected the summary is scoped to
                        // that range (range-labeled tiles); otherwise it shows
                        // the global today/weekly/total dashboard.
                        _buildStatsGrid(
                          context,
                          (reportsProvider.startDate != null && reportsProvider.endDate != null)
                              ? [
                                  _StatItem('reports.range_revenue'.tr(), '₹${(data?.totalSales ?? 0).toStringAsFixed(2)}', Icons.insights, AppColors.primaryBlue),
                                  _StatItem('reports.range_orders'.tr(), '${data?.totalOrders ?? 0}', Icons.shopping_bag_outlined, AppColors.primaryBlue),
                                  _StatItem('reports.range_upi'.tr(), '₹${(data?.totalUpiSales ?? 0).toStringAsFixed(2)}', Icons.account_balance, AppColors.primaryBlue),
                                  _StatItem('reports.range_cash'.tr(), '₹${(data?.totalCashSales ?? 0).toStringAsFixed(2)}', Icons.payments, AppColors.primaryGreen),
                                ]
                              : [
                                  _StatItem('reports.today_revenue'.tr(), '₹${(data?.todayRevenue ?? 0).toStringAsFixed(2)}', Icons.today, AppColors.primaryBlue),
                                  _StatItem('reports.weekly_sales'.tr(), '₹${(data?.weeklySales ?? 0).toStringAsFixed(2)}', Icons.calendar_view_week, Colors.green),
                                  _StatItem(
                                    'reports.total_sales'.tr(),
                                    '₹${(data?.totalSales ?? 0).toStringAsFixed(2)}',
                                    Icons.account_balance_wallet_outlined,
                                    AppColors.primaryBlue,
                                  ),
                                  _StatItem(
                                    'reports.total_orders'.tr(),
                                    '${data?.totalOrders ?? 0}',
                                    Icons.shopping_bag_outlined,
                                    AppColors.primaryBlue,
                                  ),
                                  _StatItem(
                                    'reports.today_upi'.tr(),
                                    '₹${(data?.todayUpiPayment ?? 0).toStringAsFixed(2)}',
                                    Icons.account_balance_outlined,
                                    AppColors.primaryBlue,
                                  ),
                                  _StatItem(
                                    'reports.today_cash'.tr(),
                                    '₹${(data?.todayCashPayment ?? 0).toStringAsFixed(2)}',
                                    Icons.money,
                                    AppColors.primaryGreen,
                                  ),
                                  _StatItem(
                                    'reports.total_upi_sales'.tr(),
                                    '₹${(data?.totalUpiSales ?? 0).toStringAsFixed(2)}',
                                    Icons.account_balance,
                                    AppColors.primaryBlue,
                                  ),
                                  _StatItem(
                                    'reports.total_cash_sales'.tr(),
                                    '₹${(data?.totalCashSales ?? 0).toStringAsFixed(2)}',
                                    Icons.payments,
                                    AppColors.primaryGreen,
                                  ),
                                ],
                        ),
                        SizedBox(height: 22.h),
                        _buildOrderStatusChart(context, provider.allOrders),
                        SizedBox(height: 18.h),
                        _buildPaymentTypeChart(context, provider.allOrders),
                        SizedBox(height: 22.h),
                        _buildSectionTitle(context, 'reports.order_history'.tr(), Icons.receipt_long_outlined),
                        SizedBox(height: 10.h),
                        if (orderResource is Loading && provider.allOrders.isEmpty)
                          const Center(
                            child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()),
                          )
                        else if (provider.allOrders.isEmpty)
                          _buildEmptyOrdersState(context)
                        else
                          ResponsivePairedList<OrderModel>(
                            items: provider.allOrders,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, order) => OrderCard(order: order, showActionButton: false, showDate: true),
                          ),
                        if (orderResource is Success &&
                            provider.pagination != null &&
                            provider.pagination!.currentPage < provider.pagination!.lastPage)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  reportsProvider.setCurrentPage(reportsProvider.currentPage + 1);
                                  reportsProvider.fetchData(orderProvider, isRefresh: false);
                                },
                                icon: Icon(Icons.expand_more, size: 18.sp),
                                label: Text('reports.load_more'.tr()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                ),
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildEmptyOrdersState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40.sp, color: AppColors.grey.withValues(alpha: 0.5)),
          SizedBox(height: 8.h),
          Text(
            'reports.no_orders'.tr(),
            style: TextStyle(color: AppColors.grey, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ReportsProvider reportsProvider, OrderProvider orderProvider) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(sizeFactor: animation, axis: Axis.horizontal, axisAlignment: -1, child: child),
                    );
                  },
                  child: reportsProvider.isSearching
                      ? TextField(
                          key: const ValueKey('searchField'),
                          controller: reportsProvider.searchController,
                          autofocus: true,
                          style: TextStyle(fontSize: 14.sp, color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'common.search_dots'.tr(),
                            hintStyle: TextStyle(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              fontSize: 14.sp,
                            ),
                            prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue, size: 20.sp),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.close, size: 18.sp, color: AppColors.grey),
                              onPressed: () {
                                reportsProvider.toggleSearching();
                                reportsProvider.fetchData(orderProvider);
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: theme.scaffoldBackgroundColor,
                            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                          ),
                          onChanged: (value) => reportsProvider.fetchData(orderProvider),
                        )
                      : Row(
                          key: const ValueKey('filterHeader'),
                          children: [
                            Icon(Icons.tune_rounded, size: 18.sp, color: theme.textTheme.titleMedium?.color),
                            SizedBox(width: 6.w),
                            Text(
                              'reports.filter_records'.tr(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleMedium?.color,
                              ),
                            ),
                            const Spacer(),
                            _buildRoundIconButton(
                              icon: Icons.search,
                              color: AppColors.primaryBlue,
                              isEnabled: true,
                              onTap: () => reportsProvider.toggleSearching(),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  label: reportsProvider.startDate == null
                      ? 'reports.start_date'.tr()
                      : DateFormat('yyyy-MM-dd').format(reportsProvider.startDate!),
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context, true, reportsProvider, orderProvider),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildDateField(
                  context,
                  label: reportsProvider.endDate == null ? 'reports.end_date'.tr() : DateFormat('yyyy-MM-dd').format(reportsProvider.endDate!),
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context, false, reportsProvider, orderProvider),
                  isEnabled: reportsProvider.startDate != null,
                ),
              ),
              SizedBox(width: 6.w),
              _buildRoundIconButton(
                icon: Icons.delete_sweep_outlined,
                color: Colors.red,
                isEnabled: reportsProvider.startDate != null && reportsProvider.endDate != null,
                onTap: () => _deleteRecords(context, reportsProvider, orderProvider),
              ),
              if (reportsProvider.startDate != null || reportsProvider.endDate != null) ...[
                SizedBox(width: 6.w),
                _buildRoundIconButton(
                  icon: Icons.clear,
                  color: Colors.grey,
                  isEnabled: true,
                  onTap: () {
                    reportsProvider.clearDates();
                    reportsProvider.fetchData(orderProvider);
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(9.w),
        decoration: BoxDecoration(
          color: isEnabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isEnabled ? color.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, size: 18.sp, color: isEnabled ? color : Colors.grey),
      ),
    );
  }

  Widget _buildStatusTabs(BuildContext context, ReportsProvider reportsProvider, OrderProvider orderProvider) {
    List<String> statuses;
    if (reportsProvider.selectedOrderType == 'common.takeaway'.tr()) {
      statuses = ['common.all'.tr(), 'order.status.pending'.tr(), 'reports.running'.tr(), 'order.status.completed'.tr(), 'order.status.cancelled'.tr(), 'order.status.dispatched'.tr()];
    } else if (reportsProvider.selectedOrderType == 'reports.dinein'.tr()) {
      statuses = ['common.all'.tr(), 'order.status.pending'.tr(), 'order.status.completed'.tr()];
    } else {
      statuses = ['common.all'.tr(), 'order.status.pending'.tr(), 'reports.running'.tr(), 'order.status.completed'.tr(), 'order.status.cancelled'.tr(), 'order.status.dispatched'.tr()];
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
          final isSelected = reportsProvider.selectedStatus == status;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  reportsProvider.setSelectedStatus(status);
                  reportsProvider.fetchData(orderProvider);
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

  Widget _buildOrderTypeTabs(BuildContext context, ReportsProvider reportsProvider, OrderProvider orderProvider) {
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
            'reports.order_category'.tr(),
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.grey, letterSpacing: 0.8),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 48.h,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12.r)),
            child: Row(
              children: [
                _buildTypeToggleItem(reportsProvider, orderProvider, 'common.all'.tr(), Icons.list_alt_rounded),
                _buildTypeToggleItem(reportsProvider, orderProvider, 'common.takeaway'.tr(), Icons.shopping_bag_outlined),
                _buildTypeToggleItem(reportsProvider, orderProvider, 'reports.dinein'.tr(), Icons.table_restaurant_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggleItem(ReportsProvider reportsProvider, OrderProvider orderProvider, String type, IconData icon) {
    final isSelected = reportsProvider.selectedOrderType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            reportsProvider.setSelectedOrderType(type);
            reportsProvider.fetchData(orderProvider);
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

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
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
            Icon(
              icon,
              size: 15.sp,
              color: isEnabled ? AppColors.primaryBlue.withValues(alpha: 0.7) : AppColors.grey.withValues(alpha: 0.3),
            ),
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

  Widget _buildSectionTitle(BuildContext context, String title, [IconData? icon]) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 16.h,
          decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(2.r)),
        ),
        SizedBox(width: 8.w),
        if (icon != null) ...[
          Icon(icon, size: 17.sp, color: Theme.of(context).textTheme.titleMedium?.color),
          SizedBox(width: 6.w),
        ],
        Text(
          title,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, List<_StatItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      // Fixed 2-column grid makes each stat card span half the tablet's
      // width, which looks stretched in both orientations. On tablet, size
      // columns from a max width so more stat cards fit per row instead.
      // Phone layout (fixed 2 columns) is untouched.
      gridDelegate: Responsive.isTablet(context)
          ? SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260.w,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              mainAxisExtent: 74.h,
            )
          : SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              mainAxisExtent: 74.h,
            ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: item.color.withValues(alpha: 0.12)),
            boxShadow: AppColors.subtleShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
                child: Icon(item.icon, color: item.color, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.sp, color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusChart(BuildContext context, List<OrderModel> orders) {
    if (orders.isEmpty) return const SizedBox.shrink();

    final Map<OrderStatus, int> counts = {
      OrderStatus.pending: 0,
      OrderStatus.running: 0,
      OrderStatus.completed: 0,
      OrderStatus.cancelled: 0,
      OrderStatus.dispatched: 0,
    };

    for (var order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }

    final total = orders.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'reports.order_status_dist'.tr(), Icons.pie_chart_outline_rounded),
          SizedBox(height: 20.h),
          SizedBox(
            height: 180.h,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 35.r,
                          sections: [
                            _buildPieSection(counts[OrderStatus.pending]!, total, Colors.orange),
                            _buildPieSection(counts[OrderStatus.running]!, total, AppColors.primaryBlue),
                            _buildPieSection(counts[OrderStatus.completed]!, total, AppColors.primaryGreen),
                            _buildPieSection(counts[OrderStatus.cancelled]!, total, AppColors.errorRed),
                            _buildPieSection(counts[OrderStatus.dispatched]!, total, Colors.blueGrey),
                          ].where((s) => s.value > 0).toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            'common.total'.tr(),
                            style: TextStyle(fontSize: 9.sp, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegend(context, 'order.status.pending'.tr(), counts[OrderStatus.pending]!, Colors.orange),
                      _buildChartLegend(context, 'reports.running'.tr(), counts[OrderStatus.running]!, AppColors.primaryBlue),
                      _buildChartLegend(context, 'order.status.completed'.tr(), counts[OrderStatus.completed]!, AppColors.primaryGreen),
                      _buildChartLegend(context, 'order.status.cancelled'.tr(), counts[OrderStatus.cancelled]!, AppColors.errorRed),
                      _buildChartLegend(context, 'order.status.dispatched'.tr(), counts[OrderStatus.dispatched]!, Colors.blueGrey),
                      Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                      _buildChartLegend(context, 'reports.total_orders'.tr(), total, Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(int count, int total, Color color) {
    final percentage = (count / total * 100).toStringAsFixed(0);
    return PieChartSectionData(
      color: color,
      value: count.toDouble(),
      title: '$percentage%',
      radius: 45.r,
      titleStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildChartLegend(BuildContext context, String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeChart(BuildContext context, List<OrderModel> orders) {
    if (orders.isEmpty) return const SizedBox.shrink();

    final Map<String, int> counts = {'pay.cash'.tr(): 0, 'pay.upi'.tr(): 0, 'pay.upi_cash'.tr(): 0, 'reports.other'.tr(): 0};

    for (var order in orders) {
      if (order.paymentType == null) {
        counts['reports.other'.tr()] = (counts['reports.other'.tr()] ?? 0) + 1;
        continue;
      }
      final type = order.paymentType!.toLowerCase();
      if (type == 'cash') {
        counts['pay.cash'.tr()] = (counts['pay.cash'.tr()] ?? 0) + 1;
      } else if (type == 'upi') {
        counts['pay.upi'.tr()] = (counts['pay.upi'.tr()] ?? 0) + 1;
      } else if (type == 'part_payment') {
        counts['pay.upi_cash'.tr()] = (counts['pay.upi_cash'.tr()] ?? 0) + 1;
      } else {
        counts['reports.other'.tr()] = (counts['reports.other'.tr()] ?? 0) + 1;
      }
    }

    final total = orders.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'reports.payment_method_dist'.tr(), Icons.account_balance_wallet_outlined),
          SizedBox(height: 20.h),
          SizedBox(
            height: 180.h,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 35.r,
                          sections: [
                            _buildPieSection(counts['pay.cash'.tr()]!, total, AppColors.primaryGreen),
                            _buildPieSection(counts['pay.upi'.tr()]!, total, AppColors.primaryBlue),
                            _buildPieSection(counts['pay.upi_cash'.tr()]!, total, Colors.orange),
                            _buildPieSection(counts['reports.other'.tr()]!, total, AppColors.grey),
                          ].where((s) => s.value > 0).toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payment, size: 20.sp, color: AppColors.grey),
                          Text(
                            'reports.method'.tr(),
                            style: TextStyle(fontSize: 8.sp, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegend(context, 'pay.cash'.tr(), counts['pay.cash'.tr()]!, AppColors.primaryGreen),
                      _buildChartLegend(context, 'pay.upi'.tr(), counts['pay.upi'.tr()]!, AppColors.primaryBlue),
                      _buildChartLegend(context, 'pay.upi_cash'.tr(), counts['pay.upi_cash'.tr()]!, Colors.orange),
                      _buildChartLegend(context, 'reports.other_pending'.tr(), counts['reports.other'.tr()]!, AppColors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.title, this.value, this.icon, this.color);
}
