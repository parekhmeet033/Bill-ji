import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/services/printer_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/resource.dart';
import '../../models/table_product_list_model.dart';
import '../../presentation/widgets/api_widgets.dart';
import '../../providers/menu_provider.dart';

/// Lets the user choose which products go on kitchen tickets. Items switched
/// off here (e.g. cold drinks, water bottles) are left off every kitchen print.
class KitchenPrintItemsScreen extends StatefulWidget {
  const KitchenPrintItemsScreen({super.key});

  @override
  State<KitchenPrintItemsScreen> createState() => _KitchenPrintItemsScreenState();
}

class _KitchenPrintItemsScreenState extends State<KitchenPrintItemsScreen> {
  final _printer = PrinterService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(context, listen: false).fetchTableProducts();
    });
  }

  Future<void> _setKitchenPrint(List<TableProductModel> products, bool enabled) async {
    await _printer.setKitchenPrint({for (final p in products) p.id: p.name}, enabled);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text('kitchen.items_title'.tr()),
      ),
      body: Consumer<MenuProvider>(
        builder: (context, menuProvider, _) {
          final resource = menuProvider.tableCategoryResource;

          if (resource is Loading && menuProvider.tableCategories.isEmpty) {
            return const LoadingWidget();
          }

          if (resource is Error && menuProvider.tableCategories.isEmpty) {
            return ApiErrorWidget(
              message: resource.failure?.message ?? 'kitchen.failed_load'.tr(),
              onRetry: () => menuProvider.fetchTableProducts(forceRefresh: true),
            );
          }

          final categories = menuProvider.tableCategories.where((c) => c.products.isNotEmpty).toList();
          if (categories.isEmpty) {
            return Center(child: Text('kitchen.no_items'.tr(), style: TextStyle(color: Colors.grey)));
          }

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              Text(
                'kprint.items_off_hint'.tr(),
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
              SizedBox(height: 12.h),
              for (final category in categories) ...[
                _buildCategoryCard(category),
                SizedBox(height: 12.h),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(TableCategoryModel category) {
    final allEnabled = category.products.every((p) => _printer.isKitchenEnabled(p.id));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: AppColors.subtleShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            title: Text(category.name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            subtitle: Text('kitchen.all_in_category'.tr(), style: TextStyle(fontSize: 11.sp)),
            trailing: _buildSwitch(allEnabled, (v) => _setKitchenPrint(category.products, v)),
          ),
          const Divider(height: 1),
          for (final product in category.products)
            ListTile(
              dense: true,
              title: Text(product.name, style: TextStyle(fontSize: 13.sp)),
              trailing: _buildSwitch(
                _printer.isKitchenEnabled(product.id),
                (v) => _setKitchenPrint([product], v),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Transform.scale(
      scale: 0.8,
      child: CupertinoSwitch(value: value, activeTrackColor: AppColors.primaryBlue, onChanged: onChanged),
    );
  }
}
