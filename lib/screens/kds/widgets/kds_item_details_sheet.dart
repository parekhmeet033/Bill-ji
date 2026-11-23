import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/kds_provider.dart';

class KdsItemDetailsSheet extends StatelessWidget {
  final KdsItem item;

  const KdsItemDetailsSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(context).padding.bottom + 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${'kds.total_quantity'.tr()}: ${item.totalQuantity.toStringAsFixed(1).replaceAll('.0', '')} ${item.unit ?? ''}',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          SizedBox(height: 10.h),
          Text(
            'kds.orders_containing'.tr(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.grey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: item.associatedOrders.length,
              separatorBuilder: (context, index) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final order = item.associatedOrders[index];
                // Find this specific item's quantity in this order
                final orderItem = order.items.firstWhere((i) => i.name.trim() == item.name.trim());
                
                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'kds.token_n'.tr(namedArgs: {'n': order.tokenNumber.toString()}),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            '${'pos.qty'.tr()}: ${orderItem.quantity}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('hh:mm a').format(order.createdAt),
                            style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${'kds.customer'.tr()}: ${order.customerName}',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                      if (order.specialNote != null && order.specialNote!.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.note_alt_outlined, color: Colors.orange, size: 14.sp),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  order.specialNote!,
                                  style: TextStyle(fontSize: 11.sp, color: Colors.orange[800], fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
