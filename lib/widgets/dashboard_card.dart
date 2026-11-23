import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_colors.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isCompact;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8.w : 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isCompact ? 10.r : 16.r),
        boxShadow: AppColors.subtleShadow,
      ),
      child: isCompact ? _buildCompactLayout(context) : _buildStandardLayout(context),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconBox(size: 16, padding: 5),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.1,
            ),
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 9.sp, color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.grey, height: 1.1),
        ),
      ],
    );
  }

  Widget _buildStandardLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconBox(size: 22, padding: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.2,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11.sp, color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconBox({required double size, required double padding}) {
    return Container(
      padding: EdgeInsets.all(padding.w),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(isCompact ? 8.r : 10.r)),
      child: Icon(icon, color: color, size: size.sp),
    );
  }
}
