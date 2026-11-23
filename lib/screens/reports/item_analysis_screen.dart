import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/item_analysis_provider.dart';
import '../../providers/order_provider.dart';
import '../../presentation/widgets/api_widgets.dart';

class ItemAnalysisScreen extends StatefulWidget {
  const ItemAnalysisScreen({super.key});

  @override
  State<ItemAnalysisScreen> createState() => _ItemAnalysisScreenState();
}

class _ItemAnalysisScreenState extends State<ItemAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analysisProvider = Provider.of<ItemAnalysisProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      analysisProvider.setFilter('ia.this_month'.tr(), orderProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ia.title'.tr()),
        elevation: 0,
      ),
      body: Consumer2<ItemAnalysisProvider, OrderProvider>(
        builder: (context, provider, orderProvider, child) {
          return Column(
            children: [
              _buildFilterBar(provider, orderProvider),
              if (provider.isLoading) _buildLoadingProgress(provider),
              Expanded(
                child: (provider.isLoading && provider.topPerformers.isEmpty)
                    ? const Center(child: LoadingWidget())
                    : provider.topPerformers.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(provider),
                      SizedBox(height: 26.h),
                      _buildSectionTitle('ia.top_performing'.tr(), Icons.trending_up_rounded, subtitle: 'ia.ranked_by'.tr()),
                      SizedBox(height: 12.h),
                      _buildTopPerformersList(provider),
                      if (provider.slowMoving.isNotEmpty) ...[
                        SizedBox(height: 30.h),
                        _buildSectionTitle('ia.slow_moving'.tr(), Icons.trending_down_rounded, subtitle: 'ia.may_need_attention'.tr()),
                        SizedBox(height: 12.h),
                        _buildSlowMovingList(provider),
                      ],
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingProgress(ItemAnalysisProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.12))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 14.w,
                height: 14.w,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  provider.loadingMessage,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                ),
              ),
              Text(
                '${(provider.fetchProgress * 100).toInt()}%',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: provider.fetchProgress,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ItemAnalysisProvider provider, OrderProvider orderProvider) {
    final filters = ['ia.today'.tr(), 'ia.yesterday'.tr(), 'ia.this_week'.tr(), 'ia.this_month'.tr()];
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        children: [
          ...filters.map((f) => Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: _filterChip(
              label: f,
              isSelected: provider.selectedFilter == f,
              onSelected: (val) {
                if (val) provider.setFilter(f, orderProvider);
              },
            ),
          )),
          _filterChip(
            label: provider.selectedFilter == 'ia.custom'.tr() ? 'ia.selected'.tr() : 'ia.custom_range'.tr(),
            icon: Icons.calendar_today,
            isSelected: provider.selectedFilter == 'ia.custom'.tr(),
            onSelected: (val) => _selectCustomRange(context, provider, orderProvider),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    IconData? icon,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.black54),
            SizedBox(width: 4.w),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: onSelected,
      selectedColor: AppColors.primaryBlue,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12.sp,
      ),
      side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 0,
      pressElevation: 0,
    );
  }

  Future<void> _selectCustomRange(BuildContext context, ItemAnalysisProvider provider, OrderProvider orderProvider) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: provider.startDate != null && provider.endDate != null
          ? DateTimeRange(start: provider.startDate!, end: provider.endDate!)
          : null,
    );
    if (picked != null) {
      provider.setCustomRange(picked.start, picked.end, orderProvider);
    }
  }

  Widget _buildSummaryCards(ItemAnalysisProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'ia.total_quantity'.tr(),
            provider.totalQuantity.toStringAsFixed(1).replaceAll('.0', ''),
            Icons.shopping_bag_outlined,
            Colors.orange,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _summaryCard(
            'ia.total_revenue'.tr(),
            '₹${NumberFormat('#,##,###').format(provider.totalRevenue)}',
            Icons.account_balance_wallet_outlined,
            AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(height: 10.h),
          Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.black)),
          SizedBox(height: 2.h),
          Text(title, style: TextStyle(fontSize: 11.sp, color: AppColors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {String? subtitle}) {
    return Row(
      children: [
        Container(width: 4.w, height: 16.h, decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(2.r))),
        SizedBox(width: 8.w),
        Icon(icon, size: 17.sp, color: Colors.black87),
        SizedBox(width: 6.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10.5.sp, color: AppColors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformersList(ItemAnalysisProvider provider) {
    final data = provider.topPerformers;
    if (data.isEmpty) return const SizedBox.shrink();

    final maxQty = data.first.quantity;
    const rankColors = [Color(0xFFFFB020), Color(0xFF9AA5B1), Color(0xFFCD7F32)];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        separatorBuilder: (context, index) => SizedBox(height: 18.h),
        itemBuilder: (context, index) {
          final item = data[index];
          final progress = item.quantity / maxQty;
          final rankColor = index < 3 ? rankColors[index] : AppColors.grey;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rankColor.withValues(alpha: index < 3 ? 0.15 : 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.w900, color: rankColor),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '₹${NumberFormat('#,##,###').format(item.revenue)}',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Stack(
                children: [
                  Container(
                    height: 14.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: progress),
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 14.h,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(7.r),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        _formatQuantity(item.quantity, item.unit),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: progress > 0.4 ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlowMovingList(ItemAnalysisProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.slowMoving.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
        itemBuilder: (context, index) {
          final item = provider.slowMoving[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              radius: 14.r,
              child: Text('${index + 1}', style: TextStyle(fontSize: 10.sp, color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
            subtitle: Text('ia.consider_promo'.tr(), style: TextStyle(fontSize: 10.sp, color: AppColors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(_formatQuantity(item.quantity, item.unit),
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.red)),
                ),
                SizedBox(height: 3.h),
                Text('₹${item.revenue.toStringAsFixed(0)}', style: TextStyle(fontSize: 10.sp, color: AppColors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatQuantity(double q, String unit) {
    if (unit.toUpperCase() == 'KG') {
      if (q < 1.0) return '${(q * 1000).toInt()} gm';
      return '${q.toStringAsFixed(1).replaceAll('.0', '')} kg';
    } else if (unit.toLowerCase() == 'nos') {
      return '${q.toInt()} Nos';
    } else if (unit.toLowerCase() == 'plate') {
      // Plate items show just the quantity (no 'Plt' suffix).
      return q.toStringAsFixed(1).replaceAll('.0', '');
    }
    return '${q.toStringAsFixed(1).replaceAll('.0', '')} $unit';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.analytics_outlined, size: 40.sp, color: AppColors.primaryBlue.withValues(alpha: 0.5)),
            ),
            SizedBox(height: 16.h),
            Text('ia.no_data'.tr(), style: TextStyle(color: Colors.black87, fontSize: 15.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 6.h),
            Text(
              'ia.try_different'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 12.5.sp),
            ),
          ],
        ),
      ),
    );
  }
}