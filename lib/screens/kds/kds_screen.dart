import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/kds_provider.dart';
import '../../providers/navigation_provider.dart';
import 'widgets/kds_item_details_sheet.dart';

class KdsScreen extends StatelessWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('kds.title'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setTab(NavTab.home),
        ),
      ),
      body: Consumer<KdsProvider>(
        builder: (context, provider, child) {
          final items = provider.aggregatedItems;

          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          return GridView.builder(
            padding: EdgeInsets.all(16.w),
            // Fixed 2-column grid leaves each card stretched extremely wide
            // on a tablet, especially in landscape. On tablet, size columns
            // from a max width instead so more cards fit per row. Phone
            // layout (fixed 2 columns) is untouched.
            gridDelegate: Responsive.isTablet(context)
                ? SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260.w,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    mainAxisExtent: 130.h,
                  )
                : SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    mainAxisExtent: 130.h,
                  ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildKdsCard(context, items[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildKdsCard(BuildContext context, KdsItem item) {
    return InkWell(
      onTap: () => _showItemDetails(context, item),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'kds.total_qty'.tr(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${item.totalQuantity.toStringAsFixed(1).replaceAll('.0', '')} ${item.unit ?? ''}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${item.associatedOrders.length} Orders',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_outlined, size: 64.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'kds.no_active'.tr(),
            style: TextStyle(fontSize: 15.sp, color: AppColors.grey, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8.h),
          Text(
            'kds.new_appear'.tr(),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(BuildContext context, KdsItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => KdsItemDetailsSheet(item: item),
    );
  }
}
