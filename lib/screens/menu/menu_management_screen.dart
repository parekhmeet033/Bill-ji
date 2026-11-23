import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/resource.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/api_constants.dart';
import '../../models/menu_item_model.dart';
import '../../models/category_model.dart';
import '../../providers/add_menu_item_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/menu_management_provider.dart';
import '../../presentation/widgets/api_widgets.dart';
import '../../core/utils/custom_snackbar.dart';
import '../../providers/navigation_provider.dart';
import 'widgets/add_menu_item_dialog.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final managementProvider = Provider.of<MenuManagementProvider>(context, listen: false);

      menuProvider.fetchMenu();
      menuProvider.fetchCategories().then((_) {
        managementProvider.syncLocalCategories(menuProvider.categories);
      });
    });
  }

  void _syncLocalCategories() {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final managementProvider = Provider.of<MenuManagementProvider>(context, listen: false);
    managementProvider.syncLocalCategories(menuProvider.categories);
  }

  void _syncLocalMenuItems() {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final managementProvider = Provider.of<MenuManagementProvider>(context, listen: false);
    if (managementProvider.selectedCategoryId != null) {
      managementProvider.selectCategory(managementProvider.selectedCategoryId, menuProvider.menuItems);
    }
  }

  void _selectCategory(int? categoryId) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final managementProvider = Provider.of<MenuManagementProvider>(context, listen: false);
    managementProvider.selectCategory(categoryId, menuProvider.menuItems);
  }

  Future<void> _saveMenuOrder() async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final managementProvider = Provider.of<MenuManagementProvider>(context, listen: false);

    final result = await managementProvider.saveMenuOrder(menuProvider);
    if (!mounted) return;

    if (result is Success) {
      CustomSnackbar.show(context, message: 'menu.order_saved'.tr(), isError: false);
    } else if (result is Error) {
      CustomSnackbar.show(context, message: result.failure?.message ?? 'menu.failed_save_order'.tr());
    }
  }

  Widget _buildMenuSaveOrderButton(MenuManagementProvider managementProvider) {
    return GestureDetector(
      onTap: managementProvider.isSavingMenuOrder ? null : _saveMenuOrder,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10.r)),
        child: managementProvider.isSavingMenuOrder
            ? Center(
                child: SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 18.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text(
                    'menu.save_order'.tr(),
                    style: TextStyle(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final managementProvider = context.watch<MenuManagementProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text('menu.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setTab(NavTab.home),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: TextButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: Icon(Icons.add_circle, size: 20.sp, color: Colors.white),
              label: Text(
                'menu.add_item'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategorySidebar(managementProvider),
                VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.1), thickness: 1),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        if (managementProvider.selectedCategoryId == null) _buildFilterChips(managementProvider),
                        if (managementProvider.hasMenuReordered) _buildMenuSaveOrderButton(managementProvider),
                        Expanded(child: _buildBody(menuProvider, managementProvider)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar(MenuManagementProvider managementProvider) {
    return Container(
      width: 75.w,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildCategoryTile(
            managementProvider,
            name: 'common.all'.tr(),
            icon: Icons.grid_view_rounded,
            category: null,
            itemCount: Provider.of<MenuProvider>(context, listen: false).menuItems.length,
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.only(top: 0, bottom: 4.h),
              itemCount: managementProvider.localCategories.length,
              onReorder: managementProvider.reorderCategories,
              proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, elevation: 4, child: child),
              itemBuilder: (context, index) {
                final category = managementProvider.localCategories[index];
                return KeyedSubtree(
                  key: ValueKey(category.id),
                  child: _buildCategoryTile(
                    managementProvider,
                    name: category.name,
                    icon: Icons.restaurant_menu,
                    category: category,
                    itemCount: category.productsCount,
                  ),
                );
              },
            ),
          ),
          if (managementProvider.hasReordered) _buildSaveOrderButton(managementProvider),
          _buildAddCategoryButton(),
        ],
      ),
    );
  }

  Widget _buildSaveOrderButton(MenuManagementProvider managementProvider) {
    return GestureDetector(
      onTap: managementProvider.isSavingOrder ? null : _saveOrder,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10.r)),
        child: managementProvider.isSavingOrder
            ? Center(
                child: SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18.sp, color: Colors.white),
                    SizedBox(height: 2.h),
                    Text(
                      'common.save'.tr(),
                      style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final managementProvider = Provider.of<MenuManagementProvider>(context, listen: false);

    final result = await managementProvider.saveCategoryOrder(menuProvider);
    if (!mounted) return;

    if (result is Success) {
      CustomSnackbar.show(context, message: 'menu.order_saved'.tr(), isError: false);
    } else if (result is Error) {
      CustomSnackbar.show(context, message: result.failure?.message ?? 'menu.failed_save_order'.tr());
    }
  }

  Widget _buildCategoryTile(
    MenuManagementProvider managementProvider, {
    required String name,
    required IconData icon,
    CategoryModel? category,
    int itemCount = 0,
  }) {
    final isSelected = category == null
        ? managementProvider.selectedCategoryId == null
        : managementProvider.selectedCategoryId == category.id;

    return GestureDetector(
      onTap: () {
        if (category != null && managementProvider.selectedCategoryId == category.id) {
          _showCategoryOptions(category);
        } else {
          _selectCategory(category?.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.w,
              height: 45.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: category?.image != null
                  ? CachedNetworkImage(
                      imageUrl: '${category!.image}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Icon(icon, size: 22.sp, color: isSelected ? Colors.white : AppColors.grey),
                      errorWidget: (context, url, error) =>
                          Icon(icon, size: 22.sp, color: isSelected ? Colors.white : AppColors.grey),
                    )
                  : Icon(icon, size: 22.sp, color: isSelected ? Colors.white : AppColors.grey),
            ),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryBlue : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '$itemCount',
              style: TextStyle(
                fontSize: 9.sp,
                color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.8) : AppColors.grey.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return GestureDetector(
      onTap: () => _showCategoryDialog(),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45.w,
              height: 45.w,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Icon(Icons.add, size: 22.sp, color: AppColors.primaryBlue),
            ),
            SizedBox(height: 6.h),
            Text(
              'common.add'.tr(),
              style: TextStyle(fontSize: 10.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryOptions(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(height: 12.h),
            Text(
              category.name,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 8.h),
            const Divider(),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.blue),
              title: Text('common.edit'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _showCategoryDialog(category: category);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('common.delete'.tr(), style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteCategory(category);
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog({CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryDialog(category: category),
    ).then((refreshed) {
      if (refreshed == true && mounted) {
        Provider.of<MenuProvider>(context, listen: false).fetchCategories().then((_) => _syncLocalCategories());
      }
    });
  }

  void _confirmDeleteCategory(CategoryModel category) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final managementProvider = Provider.of<MenuManagementProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('menu.delete_category'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('menu.delete_category_confirm'.tr(namedArgs: {'name': category.name})),
            if (category.productsCount > 0) ...[
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'menu.category_items_warning'.tr(namedArgs: {'n': category.productsCount.toString()}),
                        style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await menuProvider.deleteCategory(category.id);
              if (mounted) {
                if (result is Success) {
                  if (managementProvider.selectedCategoryId == category.id) _selectCategory(null);
                  await menuProvider.fetchMenu();
                  await menuProvider.fetchCategories();
                  if (mounted) {
                    _syncLocalCategories();
                    _syncLocalMenuItems();
                    CustomSnackbar.show(context, message: 'menu.category_deleted'.tr(), isError: false);
                  }
                } else {
                  CustomSnackbar.show(context, message: (result as Error).failure?.message ?? 'menu.failed_delete'.tr());
                }
              }
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(MenuManagementProvider managementProvider) {
    return Container(
      height: 45.h,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _filterChip(managementProvider, 'common.all'.tr(), AppColors.primaryBlue),
          SizedBox(width: 8.w),
          _filterChip(managementProvider, 'menu.visible'.tr(), Colors.green),
          SizedBox(width: 8.w),
          _filterChip(managementProvider, 'menu.hidden'.tr(), Colors.red),
        ],
      ),
    );
  }

  Widget _filterChip(MenuManagementProvider managementProvider, String label, Color color) {
    bool isSelected = managementProvider.selectedFilter == label;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) managementProvider.setSelectedFilter(label);
      },
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : theme.textTheme.bodySmall?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.sp,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: isSelected ? color : theme.dividerColor.withValues(alpha: 0.1)),
      ),
      backgroundColor: theme.cardColor,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }

  Widget _buildBody(MenuProvider provider, MenuManagementProvider managementProvider) {
    final resource = provider.menuResource;

    if (resource is Loading) {
      return const LoadingWidget();
    }

    if (resource is Error) {
      return ApiErrorWidget(message: resource.failure?.message ?? 'common.failed_load_menu'.tr(), onRetry: () => provider.fetchMenu());
    }

    if (managementProvider.selectedCategoryId != null) {
      return RefreshIndicator(
        onRefresh: () async {
          await provider.fetchMenu();
          await provider.fetchCategories();
          if (mounted) {
            _syncLocalCategories();
            _syncLocalMenuItems();
          }
        },
        color: AppColors.primaryBlue,
        child: managementProvider.localMenuItems.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 0.6.sh,
                  child: Center(
                    child: Text(
                      'menu.no_items_category'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey, fontSize: 14.sp),
                    ),
                  ),
                ),
              )
            : ReorderableListView.builder(
                padding: EdgeInsets.all(12.w),
                itemCount: managementProvider.localMenuItems.length,
                onReorder: managementProvider.reorderMenuItems,
                proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, elevation: 4, child: child),
                itemBuilder: (context, index) {
                  return SizedBox(
                    key: ValueKey(managementProvider.localMenuItems[index].id),
                    height: 125.h,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _buildMenuCard(
                        context,
                        managementProvider.localMenuItems[index],
                        managementProvider,
                        showDragHandle: true,
                      ),
                    ),
                  );
                },
              ),
      );
    }

    final filteredItems = provider.menuItems.where((item) {
      return managementProvider.selectedFilter == "All" ||
          (managementProvider.selectedFilter == "Visible" ? item.isAvailable : !item.isAvailable);
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchMenu();
        await provider.fetchCategories();
        if (mounted) {
          _syncLocalCategories();
          _syncLocalMenuItems();
        }
      },
      color: AppColors.primaryBlue,
      child: filteredItems.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 0.6.sh,
                child: Center(
                  child: Text(
                    'menu.no_items_found_hint'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey, fontSize: 14.sp),
                  ),
                ),
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(12.w),
              gridDelegate: Responsive.isTablet(context)
                  ? SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420.w,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      mainAxisExtent: 115.h,
                    )
                  : SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      mainAxisExtent: 115.h,
                    ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return _buildMenuCard(context, filteredItems[index], managementProvider);
              },
            ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    MenuItemModel item,
    MenuManagementProvider managementProvider, {
    bool showDragHandle = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String priceText = '';
    IconData placeholderIcon = Icons.fastfood_outlined;

    if (item.unit == PriceUnit.plate) {
      if (item.halfPrice != null && item.halfPrice != 0) {
        priceText = 'H: ₹${item.halfPrice?.toStringAsFixed(0)} / F: ₹${item.fullPrice?.toStringAsFixed(0)}';
      } else {
        // Plate items show just the price (no 'Plt' unit label).
        priceText = '₹${item.fullPrice?.toStringAsFixed(0)}';
      }
      placeholderIcon = Icons.layers_outlined;
    } else if (item.rawUnit?.toLowerCase() == 'plate') {
      // Plate items show just the price (no 'Plt' unit label).
      priceText = '₹${item.price?.toStringAsFixed(0)}';
    } else {
      String unitText = 'common.qty'.tr();
      if (item.unit == PriceUnit.weight) {
        unitText = 'Kg';
        placeholderIcon = Icons.scale_outlined;
      }
      priceText = '₹${item.price?.toStringAsFixed(0)} / $unitText';
    }

    final imageUrl = item.image != null ? '${ApiConstants.imageBaseUrl}${item.image}' : null;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle)
              Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: Center(
                  child: Icon(Icons.drag_indicator, color: AppColors.grey.withOpacity(0.5), size: 20.sp),
                ),
              ),
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Center(
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(placeholderIcon, color: AppColors.primaryBlue.withOpacity(0.5), size: 24.sp),
                    )
                  : Icon(placeholderIcon, color: AppColors.primaryBlue.withOpacity(0.5), size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDarkMode ? AppColors.softGreen : AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24.h,
                        width: 30.w,
                        child: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            value: item.isAvailable,
                            activeTrackColor: AppColors.primaryGreen,
                            inactiveTrackColor: AppColors.errorRed,
                            onChanged: (val) async {
                              final provider = Provider.of<MenuProvider>(context, listen: false);
                              final result = await provider.toggleAvailability(item.id);
                              if (!mounted) return;
                              if (result is Error) {
                                CustomSnackbar.show(context, message: result.failure?.message ?? 'menu.failed_update_status'.tr());
                              }
                              if (managementProvider.selectedCategoryId != null) {
                                final updated = provider.menuItems.firstWhere((m) => m.id == item.id, orElse: () => item);
                                managementProvider.updateLocalMenuItem(updated);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  12.verticalSpace,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionIcon(
                        icon: Icons.edit_outlined,
                        color: Colors.blue,
                        onTap: () => _showAddItemDialog(context, item: item),
                      ),
                      SizedBox(width: 4.w),
                      _buildActionIcon(
                        icon: Icons.delete_outline,
                        color: AppColors.errorRed,
                        onTap: () => _showDeleteConfirmation(context, item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4.r)),
        child: Icon(icon, size: 18.sp, color: color),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MenuItemModel item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('menu.delete_item'.tr()),
        content: Text('menu.delete_item_confirm'.tr(namedArgs: {'name': item.name})),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final provider = Provider.of<MenuProvider>(context, listen: false);
              final result = await provider.deleteMenuItem(item.id);

              if (mounted) {
                if (result is Success) {
                  CustomSnackbar.show(context, message: 'menu.item_deleted'.tr(), isError: false);
                  Provider.of<MenuManagementProvider>(context, listen: false).removeLocalMenuItem(item.id);

                  provider.fetchCategories().then((_) {
                    if (mounted) _syncLocalCategories();
                  });
                } else {
                  CustomSnackbar.show(context, message: result.failure?.message ?? 'menu.failed_delete_item'.tr());
                }
              }
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, {MenuItemModel? item}) async {
    final provider = Provider.of<MenuProvider>(context, listen: false);
    final managementProvider = Provider.of<MenuManagementProvider>(context, listen: false);
    final addMenuItemProvider = Provider.of<AddMenuItemProvider>(context, listen: false);

    addMenuItemProvider.init(item);

    if (item == null && managementProvider.selectedCategoryId != null) {
      addMenuItemProvider.setCategoryId(managementProvider.selectedCategoryId);
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddMenuItemDialog(item: item),
    );

    if (result == true && mounted) {
      final currentCategoryId = managementProvider.selectedCategoryId;

      await Future.wait([provider.fetchMenu(), provider.fetchCategories()]);

      if (mounted) {
        _syncLocalCategories();
        _selectCategory(currentCategoryId);
      }
    }
  }
}

class _CategoryDialog extends StatefulWidget {
  final CategoryModel? category;

  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  List<ProductVariantModel> _subcategories = [];
  final _picker = ImagePicker();

  bool get isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _subcategories = List<ProductVariantModel>.from(widget.category!.subcategories);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined),
              title: Text('form.camera'.tr()),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 80,
                );
                if (picked != null) setState(() => _selectedImage = File(picked.path));
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('form.gallery'.tr()),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 80,
                );
                if (picked != null) setState(() => _selectedImage = File(picked.path));
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  void _showAddSubcategoryDialog(BuildContext context) {
    final subNameCtrl = TextEditingController();
    final subPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('menu.add_subcategory'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subNameCtrl,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                labelText: 'menu.subcategory_name'.tr(),
                hintText: 'menu.category_hint'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: subPriceCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                labelText: 'form.price_label'.tr(),
                hintText: 'menu.price_hint'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = subNameCtrl.text.trim();
              final priceText = subPriceCtrl.text.trim();
              if (name.isEmpty) {
                CustomSnackbar.show(context, message: 'menu.subcategory_name_required'.tr());
                return;
              }
              final price = double.tryParse(priceText);
              if (price == null) {
                CustomSnackbar.show(context, message: 'form.valid_price'.tr());
                return;
              }
              setState(() {
                _subcategories.add(ProductVariantModel(name: name, price: price));
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('common.add'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final name = _nameController.text.trim();
    if (!isEdit && _selectedImage == null) {
      CustomSnackbar.show(context, message: 'menu.category_image_required'.tr());
      return;
    }
    if (name.isEmpty) {
      CustomSnackbar.show(context, message: 'menu.category_name_required'.tr());
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<MenuProvider>(context, listen: false);

    Resource<void> result;
    if (isEdit) {
      result = await provider.updateCategory(
        id: widget.category!.id,
        name: name,
        image: _selectedImage,
        subcategories: _subcategories,
      );
    } else {
      result = await provider.addCategory(
        name: name,
        image: _selectedImage,
        subcategories: _subcategories,
      );
    }

    if (context.mounted) {
      setState(() => _isLoading = false);
      if (result is Success) {
        Navigator.pop(context, true);
      } else {
        CustomSnackbar.show(context, message: (result as Error).failure?.message ?? 'common.something_wrong'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        isEdit ? 'menu.edit_category'.tr() : 'menu.add_category'.tr(),
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _pickImage(context),
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : (widget.category?.image != null
                          ? CachedNetworkImage(
                              imageUrl: '${widget.category!.image}',
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Icon(Icons.camera_alt_outlined, size: 24.sp, color: AppColors.primaryBlue),
                              errorWidget: (context, url, error) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 24.sp, color: AppColors.primaryBlue),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'form.photo'.tr(),
                                    style: TextStyle(fontSize: 10.sp, color: AppColors.primaryBlue),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 24.sp, color: AppColors.primaryBlue),
                                SizedBox(height: 4.h),
                                Text(
                                  'form.photo'.tr(),
                                  style: TextStyle(fontSize: 10.sp, color: AppColors.primaryBlue),
                                ),
                              ],
                            )),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'menu.category_name'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'menu.subcategories'.tr(),
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                      ),
                      OutlinedButton(
                        onPressed: () => _showAddSubcategoryDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          padding: EdgeInsets.all(6.w),
                          minimumSize: Size(32.w, 32.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        child: Icon(Icons.add, size: 18.sp),
                      ),
                    ],
                  ),
                  if (_subcategories.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Column(
                      children: List.generate(_subcategories.length, (index) {
                        final sub = _subcategories[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${sub.name}  •  ₹${sub.price.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _subcategories.removeAt(index);
                                    });
                                  },
                                  child: Icon(Icons.delete_outline, size: 18.sp, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _submit(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEdit ? 'common.update'.tr() : 'common.add'.tr(), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
