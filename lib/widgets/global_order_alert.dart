import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/app_colors.dart';
import '../providers/order_provider.dart';
import '../providers/global_alert_provider.dart';

class GlobalOrderAlert extends StatefulWidget {
  final Widget child;

  const GlobalOrderAlert({super.key, required this.child});

  @override
  State<GlobalOrderAlert> createState() => _GlobalOrderAlertState();
}

class _GlobalOrderAlertState extends State<GlobalOrderAlert> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      Provider.of<GlobalAlertProvider>(context, listen: false).init(orderProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<GlobalAlertProvider>();

    return Stack(
      children: [
        widget.child,
        if (alertProvider.showNotification)
          Positioned(
            top: 50.h,
            left: 20.w,
            right: 20.w,
            child: FadeInDown(duration: const Duration(milliseconds: 500), child: _buildNotificationCard(context, alertProvider)),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(BuildContext context, GlobalAlertProvider alertProvider) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.shopping_basket_rounded, color: AppColors.primaryBlue, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alertProvider.newOrdersCount > 1
                        ? 'alert.new_orders_received'.tr(namedArgs: {'n': '${alertProvider.newOrdersCount}'})
                        : 'alert.new_order_received'.tr(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                  Text(
                    alertProvider.newOrdersCount > 1
                        ? 'alert.multiple_arrived'.tr()
                        : 'alert.one_arrived'.tr(),
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => alertProvider.dismissNotification(),
            ),
          ],
        ),
      ),
    );
  }
}
