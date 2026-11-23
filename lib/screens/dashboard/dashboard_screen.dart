import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../providers/table_order_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';
import '../../widgets/order_card.dart';
import '../../widgets/responsive_paired_list.dart';
import '../../models/order_model.dart';
import '../orders/orders_list_screen.dart';
import '../../presentation/widgets/api_widgets.dart';
import '../../core/utils/resource.dart';
import '../pos/pos_order_screen.dart';
import '../tables/table_order_screen.dart';
import '../../models/pending_table_model.dart';
import '../../core/utils/kitchen_print.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DashboardProvider? _dashboardProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dashboardProvider ??= Provider.of<DashboardProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Sync TabController with Provider index
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    _tabController.index = dashboardProvider.tabIndex;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        dashboardProvider.setTabIndex(_tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tableProvider = Provider.of<TableProvider>(context, listen: false);

      dashboardProvider.initialize(
        orderProvider: orderProvider,
        authProvider: authProvider,
        tableProvider: tableProvider,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dashboardProvider?.stopPeriodicRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final dashboardResource = orderProvider.dashboardResource;

    // POS creates takeaway orders, so the "GO POS" action is only relevant in the
    // takeaway context (takeaway mode, or the Takeaway tab when mode is 'both').
    // It can also be turned off entirely from the Settings screen.
    final authProvider = Provider.of<AuthProvider>(context);
    final String mode = authProvider.restaurantMode.toLowerCase();
    final bool inTakeawayContext = mode == 'takeaway' || (mode == 'both' && dashboardProvider.tabIndex == 0);
    final bool showPosFab = authProvider.isGoPosEnabled && inTakeawayContext;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text('dashboard.title'.tr()),
        elevation: 0,
      ),
      floatingActionButton: showPosFab
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PosOrderScreen()),
                );
              },
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: Icon(Icons.point_of_sale_outlined),
              label: Text('dashboard.go_pos'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await orderProvider.fetchDashboard();
          await orderProvider.fetchPendingTables();
        },
        color: AppColors.primaryBlue,
        child: _buildBody(orderProvider, dashboardProvider, dashboardResource),
      ),
    );
  }

  Widget _buildBody(OrderProvider provider, DashboardProvider dashboardProvider, Resource dashboardResource) {
    if (dashboardResource is Loading && provider.dashboardData == null) {
      return const LoadingWidget();
    }

    if (dashboardResource is Error && provider.dashboardData == null) {
      return ApiErrorWidget(
        message: dashboardResource.failure?.message ?? 'Failed to load dashboard',
        onRetry: () => provider.fetchDashboard(),
      );
    }

    final data = provider.dashboardData;
    final tableProvider = Provider.of<TableProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final tableOrderProvider = Provider.of<TableOrderProvider>(context);

    // Calculate Dine-in stats from API response. A table whose amount is 0 is
    // treated as empty, so it isn't counted as occupied.
    final int occupiedTablesCount = provider.pendingTables.where((t) => t.totalAmount > 0).length;
    final double liveDineInAmount = provider.pendingTables.fold<double>(0.0, (sum, table) => sum + table.totalAmount);

    final tableCount = authProvider.tableCount;
    final mode = authProvider.restaurantMode.toLowerCase();

    final bool showToken = (mode == 'takeaway') || (mode == 'both' && dashboardProvider.tabIndex == 0);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Extra bottom space so the GO POS FAB doesn't cover the last item.
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            data?.profileBanner,
            data?.userName,
            data?.runningToken ?? '0',
            provider.shouldBlinkToken,
            showToken,
          ),
          SizedBox(height: 10.h),
          if (mode == 'both') ...[
            _buildTabSwitcher(dashboardProvider),
            SizedBox(height: 14.h),
            dashboardProvider.tabIndex == 0
                ? _buildTakeawaySection(provider)
                : _buildDineInSection(
                    provider,
                    tableProvider,
                    tableOrderProvider,
                    tableCount,
                    occupiedTablesCount,
                    liveDineInAmount,
                  ),
          ] else if (mode == 'takeaway') ...[
            _buildTakeawaySection(provider),
          ] else ...[
            _buildDineInSection(provider, tableProvider, tableOrderProvider, tableCount, occupiedTablesCount, liveDineInAmount),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(DashboardProvider dashboardProvider) {
    return Container(
      height: 45.h,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12.r)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(borderRadius: BorderRadius.circular(10.r), color: AppColors.primaryBlue),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Takeaway'),
          Tab(text: 'Dine-in'),
        ],
      ),
    );
  }

  Widget _buildTakeawaySection(OrderProvider provider) {
    final data = provider.dashboardData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGrid(data?.todayTotalOrders ?? 0, data?.todayPendingOrders ?? 0, data?.todayDispatchedOrders ?? 0),
        SizedBox(height: 24.h),
        _buildSectionHeader(),
        SizedBox(height: 8.h),
        _buildOrderList(provider),
      ],
    );
  }

  Widget _buildDineInSection(
    OrderProvider orderProvider,
    TableProvider tableProvider,
    TableOrderProvider tableOrderProvider,
    int totalTables,
    int activeTables,
    double totalAmount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDineInGrid(totalTables, activeTables, totalAmount),
        SizedBox(height: 24.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text(
              'dashboard.floor_layout'.tr(),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersListScreen("Floor")));
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: Size(50.w, 28.h),
              ),
              child: Text('dashboard.view_orders'.tr(), style: TextStyle(fontSize: 13.sp)),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildTableGrid(orderProvider, tableProvider, tableOrderProvider, totalTables),
      ],
    );
  }

  Widget _buildDineInGrid(int total, int active, double amount) {
    final gridDelegate = Responsive.isTablet(context)
        ? SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200.w,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 2.2,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 1.9,
          );

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: gridDelegate,
      children: [
        DashboardCard(
          title: 'dashboard.total_tables'.tr(),
          value: '$total',
          icon: Icons.table_restaurant_outlined,
          color: AppColors.primaryBlue,
          isCompact: true,
        ),
        DashboardCard(
          title: 'dashboard.occupied'.tr(),
          value: '$active',
          icon: Icons.person_outline_rounded,
          color: Colors.orange,
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildTableGrid(
    OrderProvider orderProvider,
    TableProvider tableProvider,
    TableOrderProvider tableOrderProvider,
    int count,
  ) {
    // Only show tables up to the configured count
    final tablesToShow = tableProvider.tables.take(count).toList();

    final gridDelegate = Responsive.isTablet(context)
        ? SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150.w,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.95,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 0.9,
          );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: gridDelegate,
      itemCount: tablesToShow.length,
      itemBuilder: (context, index) {
        final table = tablesToShow[index];
        final int tableNo = int.tryParse(table.tableNumber) ?? 0;

        // Find if this table is in pending API response. A pending table whose
        // amount is 0 is treated as empty (not occupied).
        final pendingData = orderProvider.pendingTables.where((t) => t.tableNo == tableNo).toList();
        final bool isOccupiedFromServer = pendingData.isNotEmpty && pendingData.first.totalAmount > 0;
        final bool hasLocalOrder = tableOrderProvider.isTableActive(table.id);

        final bool isOccupied = isOccupiedFromServer || hasLocalOrder;

        final Color activeColor = AppColors.primaryGreen;

        return Stack(
          children: [
            InkWell(
              onTap: () {
                if (isOccupiedFromServer) {
                  tableOrderProvider.initializeFromPendingTable(pendingData.first);
                }
                Navigator.push(context, MaterialPageRoute(builder: (context) => TableOrderScreen(tableId: table.id)));
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isOccupied ? activeColor.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isOccupied ? activeColor : Colors.grey.withValues(alpha: 0.2),
                    width: isOccupied ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 4.h),
                    Icon(Icons.table_restaurant_outlined, size: 20.sp, color: isOccupied ? activeColor : Colors.grey[400]),
                    SizedBox(height: 2.h),
                    Text(
                      table.tableNumber,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: isOccupied ? activeColor : Colors.black,
                      ),
                    ),
                    Text(
                      isOccupied ? 'dashboard.occupied'.tr() : 'Empty',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                        color: isOccupied ? activeColor : Colors.grey,
                      ),
                    ),
                    if (isOccupied)
                      Text(
                        '₹${isOccupiedFromServer ? pendingData.first.totalAmount.toStringAsFixed(0) : '0'}',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                  ],
                ),
              ),
            ),
            if (isOccupiedFromServer)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: Icon(Icons.visibility_outlined, size: 18.sp, color: Colors.orange),
                  onPressed: () => _showOrderDetails(context, pendingData.first),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.all(4.w),
                ),
              ),
            if (isOccupied)
              Positioned(
                right: 6.w,
                bottom: 6.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4.r)),
                  child: Text(
                    _formatDuration(isOccupiedFromServer ? pendingData.first.createdAt : table.activeOrder?.startTime),
                    style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatWeightQuantity(double q, String unit) {
    final normalizedUnit = unit.toUpperCase();

    if (normalizedUnit == 'KG' || normalizedUnit == 'KILO') {
      if (q < 1.0) {
        return '${(q * 1000).toInt()}  gm';
      }
      return '${q.toStringAsFixed(1).replaceAll('.0', '')}  kg';
    }

    if (normalizedUnit.toLowerCase() == 'plate') {
      // Plate items show just the quantity (no 'Plt' suffix).
      return q.toStringAsFixed(1).replaceAll('.0', '');
    }

    if (normalizedUnit.toLowerCase() == 'nos' || normalizedUnit == 'NO') {
      return '${q.toInt()}  Nos';
    }

    if (q < 1.0) {
      return '${(q * 1000).toInt()} gm';
    }
    return '${q.toStringAsFixed(1).replaceAll('.0', '')} kg';
  }

  Future<void> _printKitchenTicketFromDetails(BuildContext context, PendingTableModel tableData) {
    return KitchenPrint.printTicket(
      context,
      trackingKey: KitchenPrint.tableKey(tableData.tableNo.toString()),
      tokenNumber: tableData.tableNo.toString(),
      sessionId: tableData.createdAt?.toIso8601String(),
      items: tableData.items
          .map(
            (item) => OrderItem(
              productId: item.productId,
              name: item.productName,
              quantity: KitchenPrint.formatQty(item.qty),
              price: item.price,
              total: item.total,
              unit: item.unit,
            ),
          )
          .toList(),
      note: tableData.orderNote,
      customerName: tableData.customerName,
      customerMobile: tableData.customerMobile,
    );
  }

  void _showOrderDetails(BuildContext context, PendingTableModel tableData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'dashboard.order_details_table'.tr(namedArgs: {'n': tableData.tableNo.toString()}),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              if (tableData.customerName.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    '${'kds.customer'.tr()}: ${tableData.customerName} (${tableData.customerMobile})',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
              SizedBox(height: 10.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.5),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tableData.items.length,
                  itemBuilder: (context, index) {
                    final item = tableData.items[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Text(
                            _formatWeightQuantity(item.qty, item.unit ?? 'KG'),
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                                ),
                                // Sub-category / customization for this item.
                                if ((item.note ?? '').trim().isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2.h),
                                    child: Text(
                                      item.note!.trim(),
                                      style: TextStyle(fontSize: 11.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item.total.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'order.total_amount'.tr(),
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.grey),
                    ),
                    Text(
                      '₹${tableData.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _printKitchenTicketFromDetails(sheetContext, tableData),
                  icon: Icon(Icons.print_outlined, size: 18.sp),
                  label: Text(
                    'order.kitchen_print'.tr(),
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      String? profileBanner,
      String? userName,
      String runningToken,
      bool shouldBlink,
      bool showToken,
      ) {
    return SizedBox(
      height: 60.h,
      child: Row(
        children: [
          Expanded(
            child: profileBanner != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetworkImage(
                height: 60.h,
                width: double.infinity,
                imageUrl: profileBanner.toString(),
                fit: BoxFit.cover, // was BoxFit.fill — this was distorting/stretching on tablet
                alignment: Alignment.center,
                placeholder: (context, url) => Container(color: AppColors.background, height: 60.h),
                errorWidget: (context, url, error) => _buildDefaultBrandInfo(userName),
              ),
            )
                : _buildDefaultBrandInfo(userName),
          ),
          if (showToken) ...[
            SizedBox(width: 12.w),
            if (shouldBlink)
              Flash(infinite: true, duration: const Duration(milliseconds: 1000), child: _buildRunningTokenBadge(runningToken))
            else
              _buildRunningTokenBadge(runningToken),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultBrandInfo(String? userName) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.storefront, color: Colors.white, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'dashboard.welcome_back'.tr(),
                style: TextStyle(fontSize: 12.sp, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              Text(
                (userName ?? 'BillJi')[0].toUpperCase() +
                    (userName ?? 'BillJi').substring(1),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(int total, int pending, int dispatched) {
    // On tablet, the fixed 3-column + fixed aspect-ratio combo stretches
    // card height with the wide screen while the card's content stays a
    // fixed size — leaving a big empty gap. A width-based delegate (auto
    // column count) with a wider aspect ratio keeps cards compact and
    // adapts automatically to both portrait and landscape. Phones are
    // untouched — same GridView.count as before.
    final gridDelegate = Responsive.isTablet(context)
        ? SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200.w,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 2.2,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 1.3,
          );

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: gridDelegate,
      children: [
        DashboardCard(
          title: 'dashboard.total_order'.tr(),
          value: '$total',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.primaryBlue,
          isCompact: true,
        ),
        DashboardCard(
          title: 'dashboard.pending_order'.tr(),
          value: '$pending',
          icon: Icons.pending_actions,
          color: Colors.orange,
          isCompact: true,
        ),
        DashboardCard(
          title: 'dashboard.dispatch_order'.tr(),
          value: '$dispatched',
          icon: Icons.check_circle_outline,
          color: AppColors.primaryGreen,
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'dashboard.recent_orders'.tr(),
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersListScreen("")));
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            minimumSize: Size(50.w, 28.h),
          ),
          child: Text('dashboard.view_all'.tr(), style: TextStyle(fontSize: 13.sp)),
        ),
      ],
    );
  }

  Widget _buildOrderList(OrderProvider orderProvider) {
    return ResponsivePairedList<OrderModel>(
      items: orderProvider.takeawayOrders,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      spacing: 8,
      itemBuilder: (context, order) => OrderCard(order: order),
    );
  }

  Widget _buildRunningTokenBadge(String token) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'dashboard.running'.tr(),
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10.sp, fontWeight: FontWeight.w500),
            ),
            Text(
              token,
              style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(DateTime? startTime) {
    if (startTime == null) return 'Active';
    final duration = DateTime.now().difference(startTime);
    final minutes = duration.inMinutes;
    if (minutes < 0) return '0m';
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = duration.inHours;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
}
