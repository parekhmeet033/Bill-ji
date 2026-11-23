import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_order_provider.dart';
import '../../providers/table_order_view_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/utils/resource.dart';
import '../../core/services/printer_service.dart';
import '../../presentation/widgets/api_widgets.dart';
import '../../core/utils/custom_snackbar.dart';
import '../../core/utils/kitchen_print.dart';
import '../../models/table_product_list_model.dart';

class TableOrderScreen extends StatelessWidget {
  final String tableId;

  const TableOrderScreen({super.key, required this.tableId});

  void _init(BuildContext context) {
    // build() runs on every rebuild (including when the keyboard opens), so
    // only initialize once per table entry. Re-initializing on each build would
    // clear the cart's text fields and close the panel mid-typing, which made
    // the keyboard flash open then close in landscape.
    final viewProvider = Provider.of<TableOrderViewProvider>(context, listen: false);
    if (viewProvider.isInitedFor(tableId)) return;
    viewProvider.markInitedFor(tableId);

    Future.microtask(() {
      final tableOrderProvider = Provider.of<TableOrderProvider>(context, listen: false);
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      final int tNo = int.tryParse(tableId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bool alreadySynced = orderProvider.pendingTables.any((t) => t.tableNo == tNo);

      if (!alreadySynced && !tableOrderProvider.isTableActive(tableId)) {
        KitchenPrint.resetTable(tableId);
      }

      viewProvider.init(tableId, tableOrderProvider, alreadySynced: alreadySynced);
      menuProvider.fetchTableProducts(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    _init(context);

    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Consumer<TableOrderProvider>(
            builder: (context, orderProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'torder.table_n'.tr(namedArgs: {'n': tableId}),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    orderProvider.getCustomerName(tableId).isNotEmpty
                        ? 'torder.order_for'.tr(namedArgs: {'name': orderProvider.getCustomerName(tableId)})
                        : 'torder.new_order'.tr(),
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.normal, color: AppColors.grey),
                  ),
                ],
              );
            },
          ),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
          // The cart lives in a right-side panel only in landscape; in portrait
          // it opens as a bottom sheet from the bottom bar, so the toggle icon
          // is shown only in landscape.
          actions: isLandscape ? [_buildCartToggleAction(context)] : null,
        ),
        body: Consumer3<MenuProvider, TableOrderProvider, TableOrderViewProvider>(
          builder: (context, menuProvider, orderProvider, viewProvider, child) {
            final resource = menuProvider.tableCategoryResource;

            if (resource is Loading && menuProvider.tableCategories.isEmpty) {
              return const LoadingWidget();
            }

            if (resource is Error && menuProvider.tableCategories.isEmpty) {
              return ApiErrorWidget(
                message: resource.failure?.message ?? 'common.failed_load_menu'.tr(),
                onRetry: () => menuProvider.fetchTableProducts(forceRefresh: true),
              );
            }

            final double sw = MediaQuery.of(context).size.width;
            final double cartWidth = sw >= 600 ? sw * 0.40 : sw * 0.70;

            // Auto-open the panel in landscape whenever a new item is added.
            final int itemCount = orderProvider.getCart(tableId).entries.where((e) => e.value > 0).length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isLandscape && itemCount > viewProvider.lastItemCount && itemCount > 0) {
                viewProvider.setCartOpen(true);
              }
              viewProvider.updateLastItemCount(itemCount);
            });

            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchBar(context, orderProvider),
                      Expanded(
                        child: Row(
                          children: [
                            _buildCategorySidebar(context, menuProvider.tableCategories, orderProvider),
                            Expanded(child: _buildItemGrid(context, menuProvider.tableProducts, orderProvider)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Right-side cart panel — landscape only.
                if (isLandscape && viewProvider.cartOpen)
                  SizedBox(width: cartWidth, child: _buildCartPanel(context)),
              ],
            );
          },
        ),
        // Portrait keeps the original bottom bar → bottom sheet flow.
        bottomNavigationBar: isLandscape ? null : _buildCartBar(context),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, TableOrderProvider orderProvider) {
    final viewProvider = Provider.of<TableOrderViewProvider>(context, listen: false);
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: TextField(
        controller: viewProvider.searchController,
        onChanged: (v) => orderProvider.setSearch(v),
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: 'order.search_items'.tr(),
          prefixIcon: Icon(Icons.search, size: 20.sp, color: AppColors.grey),
          suffixIcon: orderProvider.searchText.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 18.sp),
                  onPressed: () {
                    viewProvider.searchController.clear();
                    orderProvider.setSearch('');
                  },
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCategorySidebar(BuildContext context, List<TableCategoryModel> categories, TableOrderProvider orderProvider) {
    return Container(
      width: 100.w,
      color: Colors.white,
      child: ListView.builder(
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final bool isAll = index == 0;
          final TableCategoryModel? cat = isAll ? null : categories[index - 1];
          final String catName = isAll ? 'common.all'.tr() : cat!.name;
          final isSelected = isAll ? orderProvider.selectedCategoryId == null : orderProvider.selectedCategoryId == cat!.id;

          return InkWell(
            onTap: () => orderProvider.setCategory(isAll ? null : cat!.id),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.12) : Colors.transparent,
                border: Border(left: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 3.5)),
              ),
              child: Text(
                catName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? AppColors.primaryBlue : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemGrid(BuildContext context, List<TableProductModel> items, TableOrderProvider orderProvider) {
    final search = orderProvider.searchText.trim().toLowerCase();
    final filteredItems = items.where((i) {
      if (search.isNotEmpty) {
        return i.name.toLowerCase().contains(search);
      }
      return orderProvider.selectedCategoryId == null || i.categoryId == orderProvider.selectedCategoryId;
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          'order.no_items_found'.tr(),
          style: TextStyle(color: AppColors.grey, fontSize: 13.sp),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<MenuProvider>(context, listen: false).fetchTableProducts(forceRefresh: true),
      color: AppColors.primaryBlue,
      child: GridView.builder(
        padding: EdgeInsets.all(10.w),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180.w,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 0.86,
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) => _buildItemCard(context, filteredItems[index], orderProvider),
      ),
    );
  }

  void _showNewDishDialog(
    BuildContext context,
    TableProductModel item,
    TableOrderProvider orderProvider, {
    String sessionId = '',
  }) {
    final targetSessionId = sessionId.isNotEmpty ? sessionId : tableId;
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    final nameController = TextEditingController(text: item.name == 'order.new_dish'.tr() ? '' : item.name);
    final priceController = TextEditingController(text: double.tryParse(item.price) == 100 ? '' : item.price);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
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
                    'order.add_new_dish'.tr(),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: 12.h),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'menu.item_name_req'.tr(),
                  hintText: 'form.item_name_hint'.tr(),
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                  contentPadding: EdgeInsets.all(12.w),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'form.price_label'.tr(),
                  hintText: 'form.price_hint'.tr(),
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                  contentPadding: EdgeInsets.all(12.w),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final dishName = nameController.text.trim();
                    final priceText = priceController.text.trim();
                    if (dishName.isEmpty) {
                      CustomSnackbar.show(ctx, message: 'form.item_name_err'.tr());
                      return;
                    }
                    final price = double.tryParse(priceText);
                    if (price == null || price <= 0) {
                      CustomSnackbar.show(ctx, message: 'form.valid_price'.tr());
                      return;
                    }

                    Navigator.pop(ctx);

                    final basePrice = double.tryParse(item.price) ?? 0.0;
                    orderProvider.setSelectedVariant(
                      targetSessionId,
                      item.id,
                      dishName,
                      additionalPrice: price - basePrice,
                    );

                    orderProvider.updateQuantity(
                      targetSessionId,
                      item.id,
                      1.0,
                      allProducts: menuProvider.tableProducts,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text(
                    'order.add_to_order'.tr(),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomizationDialog(
    BuildContext context,
    TableProductModel item,
    TableOrderProvider orderProvider,
  ) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    if (item.isNewDishCategory(menuProvider.tableCategories)) {
      _showNewDishDialog(context, item, orderProvider);
      return;
    }

    final options = item.options;
    final Set<int> selectedIndices = {};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final double basePrice = double.tryParse(item.price) ?? 0.0;
          double additionalPrice = 0.0;
          for (final idx in selectedIndices) {
            additionalPrice += options[idx].price;
          }
          final double totalUnitPrice = basePrice + additionalPrice;

          return Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
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
                            'order.customise_x'.tr(namedArgs: {'name': item.name}),
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          Text(
                            'order.select_subcat'.tr(),
                            style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(),
                SizedBox(height: 8.h),
                Column(
                  children: List.generate(options.length, (index) {
                    final opt = options[index];
                    final isChecked = selectedIndices.contains(index);

                    return Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      decoration: BoxDecoration(
                        color: isChecked ? AppColors.primaryBlue.withValues(alpha: 0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isChecked ? AppColors.primaryBlue : Colors.grey.shade300,
                          width: isChecked ? 1.5 : 1.0,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isChecked,
                        activeColor: AppColors.primaryBlue,
                        dense: true,
                        title: Text(
                          opt.name,
                          style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        secondary: opt.price > 0
                            ? Text(
                                '+ ₹${opt.price.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                              )
                            : null,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedIndices.add(index);
                            } else {
                              selectedIndices.remove(index);
                            }
                          });
                        },
                      ),
                    );
                  }),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final List<String> allNotes = [];
                      for (final idx in selectedIndices) {
                        final o = options[idx];
                        allNotes.add(o.price > 0 ? '${o.name} (+₹${o.price.toStringAsFixed(0)})' : o.name);
                      }

                      final customizationNote = allNotes.isNotEmpty ? allNotes.join(', ') : null;

                      // Add one unit, accumulating this instance's subcategory
                      // charge and note onto the line (so a second add with a
                      // subcategory is charged for as well).
                      orderProvider.addCustomizedUnit(
                        tableId,
                        item.id,
                        note: customizationNote,
                        instanceCharge: additionalPrice,
                        allProducts: menuProvider.tableProducts,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(
                      '${'order.add_to_order'.tr()}  •  ₹${totalUnitPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWeightPicker(BuildContext context, TableProductModel item, double quantity, TableOrderProvider orderProvider) {
    final List<double> weights = [
      0.1, 0.2, 0.25, 0.3, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
    ];
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'order.select_weight_x'.tr(namedArgs: {'name': item.name}),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            if (quantity > 0)
              ListTile(
                onTap: () {
                  orderProvider.updateQuantity(tableId, item.id, 0, allProducts: menuProvider.tableProducts);
                  Navigator.pop(ctx);
                },
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'order.remove_cart'.tr(),
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 10.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 2,
                ),
                itemCount: weights.length,
                itemBuilder: (ctx, index) {
                  final w = weights[index];
                  final bool isSelected = quantity == w;
                  String label;
                  if (w < 1.0) {
                    label = '${(w * 1000).toInt()}g';
                  } else {
                    label = '${w.toStringAsFixed(1).replaceAll('.0', '')}kg';
                  }

                  return InkWell(
                    onTap: () {
                      orderProvider.updateQuantity(tableId, item.id, w, allProducts: menuProvider.tableProducts);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, TableProductModel item, TableOrderProvider orderProvider) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final double qty = orderProvider.getCart(tableId)[item.id] ?? 0;
    final String unit = item.unit?.toUpperCase() ?? 'NOS';
    final selectedVariant = orderProvider.getSelectedVariant(tableId, item.id);
    final bool isNewDishCat = item.isNewDishCategory(menuProvider.tableCategories);

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: qty > 0 ? AppColors.primaryBlue : Colors.transparent, width: 1.5),
        boxShadow: AppColors.subtleShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          if (isNewDishCat) {
            if (qty == 0) {
              _showNewDishDialog(context, item, orderProvider);
            } else {
              orderProvider.updateQuantity(tableId, item.id, qty + 1.0, allProducts: menuProvider.tableProducts);
            }
          } else if (item.isCustomizable) {
            // Subcategory item: re-open the customization dialog on every add.
            _showCustomizationDialog(context, item, orderProvider);
          } else if (unit == 'KG') {
            _showWeightPicker(context, item, qty, orderProvider);
          } else if (qty == 0) {
            orderProvider.updateQuantity(tableId, item.id, 1.0, allProducts: menuProvider.tableProducts);
          } else {
            final bool hasHalfPrice = (double.tryParse(item.halfPrice ?? '') ?? 0) > 0;
            final double step = hasHalfPrice ? 0.5 : 1.0;
            orderProvider.updateQuantity(tableId, item.id, qty + step, allProducts: menuProvider.tableProducts);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    if (selectedVariant != null && selectedVariant.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        selectedVariant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ],
                    SizedBox(height: 2.h),
                    Text(
                      unit,
                      style: TextStyle(fontSize: 9.sp, color: AppColors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${item.price}',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            qty == 0
                ? SizedBox(
                    width: double.infinity,
                    height: 28.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isNewDishCat) {
                          _showNewDishDialog(context, item, orderProvider);
                        } else if (item.isCustomizable) {
                          _showCustomizationDialog(context, item, orderProvider);
                        } else if (unit == 'KG') {
                          _showWeightPicker(context, item, qty, orderProvider);
                        } else {
                          orderProvider.updateQuantity(tableId, item.id, 1.0, allProducts: menuProvider.tableProducts);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        textStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                      child: Text('common.add'.tr()),
                    ),
                  )
                // Absorb taps on the +/- bar so a tap on its gaps or the qty
                // text doesn't fall through to the card's onTap (which would
                // add/customize the item). The +/- buttons still work.
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Container(
                    height: 28.h,
                    decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(8.r)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stepBtn(
                          Icons.remove,
                          () {
                            if (unit == 'KG') {
                              orderProvider.updateQuantity(tableId, item.id, 0, isExplicitRemove: true, allProducts: menuProvider.tableProducts);
                            } else {
                              final bool hasHalfPrice = (double.tryParse(item.halfPrice ?? '') ?? 0) > 0;
                              if (hasHalfPrice) {
                                if (qty <= 1.0) {
                                  orderProvider.updateQuantity(tableId, item.id, 0, isExplicitRemove: true, allProducts: menuProvider.tableProducts);
                                } else {
                                  orderProvider.updateQuantity(tableId, item.id, qty - 0.5, allProducts: menuProvider.tableProducts);
                                }
                              } else {
                                orderProvider.updateQuantity(tableId, item.id, qty - 1.0, isExplicitRemove: qty <= 1.0, allProducts: menuProvider.tableProducts);
                              }
                            }
                          },
                        ),
                        Text(
                          _fmtQty(qty, unit),
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        _stepBtn(
                          Icons.add,
                          () {
                            if (unit == 'KG') {
                              _showWeightPicker(context, item, qty, orderProvider);
                            } else if (item.isCustomizable && !isNewDishCat) {
                              // Re-open the customization dialog so each add can pick a subcategory.
                              _showCustomizationDialog(context, item, orderProvider);
                            } else {
                              final bool hasHalfPrice = (double.tryParse(item.halfPrice ?? '') ?? 0) > 0;
                              final double stepVal = hasHalfPrice ? 0.5 : 1.0;
                              orderProvider.updateQuantity(tableId, item.id, qty + stepVal, allProducts: menuProvider.tableProducts);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  ),
            if (item.isCustomizable) ...[
              SizedBox(height: 2.h),
              Center(
                child: Text(
                  'order.customize'.tr(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Icon(icon, color: Colors.white, size: 16.sp),
      ),
    );
  }

  String _fmtQty(double qty, String unit) {
    if (unit == 'KG') {
      return qty < 1 ? '${(qty * 1000).toStringAsFixed(0)}g' : '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1)}kg';
    }
    return qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(1);
  }

  // App-bar icon that opens/closes the right-side cart panel, with a badge
  // showing how many distinct items are in the cart.
  Widget _buildCartToggleAction(BuildContext context) {
    return Consumer3<MenuProvider, TableOrderProvider, TableOrderViewProvider>(
      builder: (context, menuProvider, orderProvider, viewProvider, _) {
        final cart = orderProvider.getCart(tableId);
        final int itemCount = cart.entries.where((e) => e.value > 0).length;
        return Padding(
          padding: EdgeInsets.only(right: 6.w),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'torder.title'.tr(),
                onPressed: () => viewProvider.toggleCart(),
                icon: Icon(
                  viewProvider.cartOpen ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  color: AppColors.primaryBlue,
                ),
              ),
              if (itemCount > 0)
                Positioned(
                  right: 4.w,
                  top: 6.h,
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                    decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
                    child: Text(
                      '$itemCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold, height: 1.1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // The cart, docked on the right of the screen. Mirrors what used to live in
  // the bottom sheet: item list, customer details, payment, total and actions.
  // The cart contents (items, customer details, payment, total, actions),
  // shared by the landscape right-side panel and the portrait bottom sheet.
  // [onDismiss] closes whichever container is presenting it.
  // [fillHeight] true fills the available height (landscape docked panel);
  // false shrink-wraps to the content height (portrait bottom sheet).
  // Small label + amount row used for the Subtotal / CGST / SGST breakdown.
  Widget _billRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.grey)),
        Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12.sp, color: AppColors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _cartInner(BuildContext context, {required VoidCallback onDismiss, bool fillHeight = true}) {
    final outerContext = context;
    return Consumer3<MenuProvider, TableOrderProvider, TableOrderViewProvider>(
      builder: (consumerContext, menuProvider, orderProvider, viewProvider, child) {
        final cart = orderProvider.getCart(tableId);
        double totalAmount = 0;
        final List<Widget> itemWidgets = [];

        for (var entry in cart.entries) {
          try {
            final product = menuProvider.tableProducts.firstWhere((p) => p.id == entry.key);
            final qty = entry.value;
            // Use the instance-aware line total so the amount keeps the
            // sub-category charge after a restart (the averaged per-unit add-on
            // isn't restored, but the instance prices are).
            final itemTotal = orderProvider.productLineTotal(tableId, product.id, menuProvider.tableProducts);
            totalAmount += itemTotal;
            final selectedVariant = orderProvider.getSelectedVariant(tableId, product.id);

            itemWidgets.add(
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Colors.black)),
                          if (selectedVariant != null && selectedVariant.isNotEmpty)
                            Text(selectedVariant, style: TextStyle(color: AppColors.primaryBlue, fontSize: 10.sp, fontWeight: FontWeight.bold))
                          else
                            Text('₹${product.price} / ${product.unit ?? 'NOS'}', style: TextStyle(color: AppColors.grey, fontSize: 10.sp)),
                        ],
                      ),
                    ),
                    _buildBottomSheetCounter(consumerContext, product, qty, orderProvider),
                    SizedBox(width: 6.w),
                    SizedBox(
                      width: 56.w,
                      child: Text('₹${itemTotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: Colors.black)),
                    ),
                    // A customized item (sub-category added) can't be deleted
                    // from the order, so hide its remove button.
                    if (!orderProvider.itemHasCustomization(tableId, product.id))
                      InkWell(
                        onTap: () => orderProvider.updateQuantity(tableId, product.id, 0, isExplicitRemove: true, allProducts: menuProvider.tableProducts),
                        child: Padding(padding: EdgeInsets.only(left: 4.w), child: Icon(Icons.remove_circle, color: Colors.red, size: 18.sp)),
                      )
                    else
                      SizedBox(width: 22.w),
                  ],
                ),
              ),
            );
          } catch (e) {}
        }

        final bool hasItems = itemWidgets.isNotEmpty;

        // GST-aware totals: the grand total (incl. GST) is what the customer
        // pays, so it drives the displayed total and the payment amounts.
        final bool gstEnabled = Provider.of<SettingsProvider>(consumerContext, listen: false).isGstEnabled;
        final totals = orderProvider.computeBillTotals(tableId, menuProvider.tableProducts, gstEnabled: gstEnabled);
        final double subtotal = totals.subtotal;
        final double gstAmount = totals.gst;
        totalAmount = totals.grandTotal;

        final Widget scrollArea = !hasItems
            ? Center(child: Text('order.no_items_found'.tr(), style: TextStyle(color: AppColors.grey, fontSize: 13.sp)))
            : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...itemWidgets,
                          const Divider(color: AppColors.lightGrey),
                          SizedBox(height: 8.h),
                          _buildCustomerDetailsFields(consumerContext, orderProvider, menuProvider.tableProducts),
                          _buildPaymentSection(consumerContext, viewProvider, totalAmount),
                          SizedBox(height: 8.h),
                          if (gstAmount > 0) ...[
                            _billRow('order.subtotal'.tr(), subtotal),
                            SizedBox(height: 4.h),
                            _billRow('CGST', totals.cgst),
                            SizedBox(height: 4.h),
                            _billRow('SGST', totals.sgst),
                            SizedBox(height: 6.h),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('order.total_amount'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                              Text('₹${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                            ],
                          ),
                        ],
                      ),
                    );

        return Column(
          mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 6.w, 6.h),
              child: Row(
                children: [
                  Text('torder.title'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                  const Spacer(),
                  IconButton(onPressed: onDismiss, icon: const Icon(Icons.close, color: Colors.black)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.lightGrey),
            fillHeight ? Expanded(child: scrollArea) : Flexible(fit: FlexFit.loose, child: scrollArea),
            if (hasItems) ...[
              const Divider(height: 1, color: AppColors.lightGrey),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _printKitchenTicketFromSheet(context: consumerContext, menuProvider: menuProvider, note: orderProvider.getOrderNote(tableId)),
                            icon: Icon(Icons.print_outlined, size: 16.sp),
                            label: Text('order.kitchen_print'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w), side: const BorderSide(color: AppColors.primaryBlue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: (orderProvider.isLoading && viewProvider.loadingAction == 'completed')
                              ? Center(child: SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue)))
                              : ElevatedButton(
                                  onPressed: orderProvider.isLoading
                                      ? null
                                      : () async {
                                          final String paymentType = viewProvider.paymentType;
                                          double upiAmount = 0;
                                          double cashAmount = 0;
                                          if (paymentType == 'cash') {
                                            cashAmount = totalAmount;
                                          } else if (paymentType == 'upi') {
                                            upiAmount = totalAmount;
                                          } else if (paymentType == 'part_payment') {
                                            upiAmount = double.tryParse(viewProvider.upiAmountController.text) ?? 0;
                                            cashAmount = double.tryParse(viewProvider.cashAmountController.text) ?? 0;
                                            if ((upiAmount + cashAmount) > totalAmount) {
                                              CustomSnackbar.show(outerContext, message: 'order.amount_exceeds'.tr());
                                              return;
                                            }
                                          }
                                          viewProvider.setLoadingAction('completed');
                                          final result = await orderProvider.saveOrder(tableId: tableId, status: 'completed', allProducts: menuProvider.tableProducts, paymentType: paymentType, upiAmount: upiAmount, cashAmount: cashAmount, gstEnabled: gstEnabled);
                                          viewProvider.setLoadingAction(null);
                                          if (outerContext.mounted) {
                                            if (result is Success<OrderModel>) {
                                              final order = result.data!;
                                              final printer = PrinterService();
                                              final ownerProvider = Provider.of<OrderProvider>(outerContext, listen: false);
                                              final bool isEthernet = printer.isEthernet;
                                              final bool hasDevice = printer.device != null;
                                              if (hasDevice || isEthernet) {
                                                printer.printReceipt(order, userName: ownerProvider.dashboardData?.userName, gstin: Provider.of<SettingsProvider>(outerContext, listen: false).gstin.trim().isNotEmpty ? Provider.of<SettingsProvider>(outerContext, listen: false).gstin : null).catchError((e) {
                                                  debugPrint('Background printing error: $e');
                                                  return false;
                                                });
                                              }
                                              onDismiss();
                                              viewProvider.resetInit();
                                              ownerProvider.fetchDashboard();
                                              ownerProvider.fetchPendingTables();
                                              Provider.of<NavigationProvider>(outerContext, listen: false).setTab(NavTab.home);
                                              CustomSnackbar.show(outerContext, message: 'torder.order_completed_table'.tr(namedArgs: {'n': tableId}), isError: false);
                                              Navigator.pop(outerContext);
                                            } else {
                                              CustomSnackbar.show(outerContext, message: (result as Error).failure?.message ?? 'torder.failed_complete'.tr());
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), elevation: 0),
                                  child: Text('torder.complete_order'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: orderProvider.isLoading ? null : () => _handleCancelOrder(outerContext, orderProvider, onDismiss: onDismiss),
                        icon: Icon(Icons.delete_outline, size: 18.sp),
                        label: Text('torder.cancel_order'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.errorRed, side: const BorderSide(color: AppColors.errorRed), padding: EdgeInsets.symmetric(vertical: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Landscape: cart docked on the right side of the screen.
  Widget _buildCartPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(left: BorderSide(color: AppColors.lightGrey)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(-4, 0))],
      ),
      child: SafeArea(
        child: _cartInner(
          context,
          onDismiss: () => Provider.of<TableOrderViewProvider>(context, listen: false).setCartOpen(false),
        ),
      ),
    );
  }

  // Portrait: a bottom bar that opens the cart as a bottom sheet (original flow).
  Widget _buildCartBar(BuildContext context) {
    return Consumer2<MenuProvider, TableOrderProvider>(
      builder: (context, menuProvider, orderProvider, child) {
        final cart = orderProvider.getCart(tableId);
        final int itemCount = cart.entries.where((e) => e.value > 0).length;
        if (itemCount == 0) return const SizedBox.shrink();
        final bool gstEnabled = Provider.of<SettingsProvider>(context, listen: false).isGstEnabled;
        final double totalAmount = orderProvider
            .computeBillTotals(tableId, menuProvider.tableProducts, gstEnabled: gstEnabled)
            .grandTotal;
        return Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, MediaQuery.of(context).padding.bottom + 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: ElevatedButton(
            onPressed: () => _showOrderBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('torder.view_order_n'.tr(namedArgs: {'n': '$itemCount'}), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
              child: SafeArea(
                top: false,
                child: _cartInner(context, onDismiss: () => Navigator.pop(sheetContext), fillHeight: false),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetCounter(
    BuildContext context,
    TableProductModel item,
    double quantity,
    TableOrderProvider orderProvider,
  ) {
    final String unit = item.unit?.toUpperCase() ?? 'NOS';
    final double step = unit == 'KG' ? 0.1 : (unit == 'PLATE' ? 0.5 : 1.0);
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    return Container(
      height: 30.h,
      decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              final newVal = double.parse((quantity - step).toStringAsFixed(1));
              if (unit == 'PLATE' ? newVal < 1.0 : newVal <= 0) {
                orderProvider.updateQuantity(tableId, item.id, 0, allProducts: menuProvider.tableProducts);
              } else {
                orderProvider.updateQuantity(tableId, item.id, newVal, allProducts: menuProvider.tableProducts);
              }
            },
            child: Container(
              width: 32.w,
              alignment: Alignment.center,
              child: Icon(Icons.remove, size: 14.sp, color: AppColors.primaryBlue),
            ),
          ),
          Text(
            _fmtQty(quantity, unit),
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
          ),
          InkWell(
            onTap: () {
              final newVal = double.parse((quantity + step).toStringAsFixed(1));
              orderProvider.updateQuantity(tableId, item.id, newVal, allProducts: menuProvider.tableProducts);
            },
            child: Container(
              width: 32.w,
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 14.sp, color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsFields(BuildContext context, TableOrderProvider orderProvider, List<TableProductModel> allProducts) {
    final viewProvider = Provider.of<TableOrderViewProvider>(context, listen: false);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallTextField(
                controller: viewProvider.nameController,
                hint: 'torder.customer_name_opt'.tr(),
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => orderProvider.setCustomerDetails(tableId, name: v, allProducts: allProducts),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildSmallTextField(
                controller: viewProvider.mobileController,
                hint: 'torder.mobile_opt'.tr(),
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (v) => orderProvider.setCustomerDetails(tableId, mobile: v, allProducts: allProducts),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _buildSmallTextField(
          controller: viewProvider.noteController,
          hint: 'torder.order_note_opt'.tr(),
          icon: Icons.note_add_outlined,
          onChanged: (v) => orderProvider.setCustomerDetails(tableId, note: v, allProducts: allProducts),
        ),
      ],
    );
  }

  Widget _buildSmallTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8.r)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(fontSize: 12.sp, color: Colors.black, height: 1.0),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 11.sp, color: AppColors.grey),
          prefixIcon: Icon(icon, size: 16.sp, color: AppColors.grey),
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // Part payment: when the user types one amount, auto-fill the remaining
  // balance into the other field (e.g. total 325, UPI 300 -> Cash 25).
  void _autoFillOther(double total, String edited, TextEditingController other) {
    final entered = double.tryParse(edited) ?? 0;
    final remaining = total - entered;
    final text = remaining > 0
        ? (remaining == remaining.roundToDouble()
            ? remaining.toStringAsFixed(0)
            : remaining.toStringAsFixed(2))
        : '';
    other.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Widget _buildPaymentSection(BuildContext context, TableOrderViewProvider viewProvider, double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.lightGrey),
        SizedBox(height: 12.h),
        Text(
          'pay.payment_type'.tr(),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _buildPaymentChip(context, 'pay.cash'.tr(), 'cash', viewProvider),
            SizedBox(width: 8.w),
            _buildPaymentChip(context, 'pay.upi'.tr(), 'upi', viewProvider),
            SizedBox(width: 8.w),
            _buildPaymentChip(context, 'pay.part_payment'.tr(), 'part_payment', viewProvider),
          ],
        ),
        if (viewProvider.paymentType == 'part_payment') ...[
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildSmallTextField(
                  controller: viewProvider.upiAmountController,
                  hint: 'pay.upi_amount'.tr(),
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _autoFillOther(totalAmount, v, viewProvider.cashAmountController),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSmallTextField(
                  controller: viewProvider.cashAmountController,
                  hint: 'pay.cash_amount'.tr(),
                  icon: Icons.money,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _autoFillOther(totalAmount, v, viewProvider.upiAmountController),
                ),
              ),
            ],
          ),
        ],
        // Cash: let the cashier enter the amount tendered and see the change due.
        if (viewProvider.paymentType == 'cash') ...[
          SizedBox(height: 16.h),
          _buildSmallTextField(
            controller: viewProvider.cashReceivedController,
            hint: 'pay.amount_received'.tr(),
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
            onChanged: (_) {},
          ),
          SizedBox(height: 10.h),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: viewProvider.cashReceivedController,
            builder: (_, value, _) {
              final received = double.tryParse(value.text.trim()) ?? 0;
              if (received <= 0) return const SizedBox.shrink();
              final double change = received - totalAmount;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('pay.return_to_customer'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('₹${(change > 0 ? change : 0).toStringAsFixed(2)}', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  ],
                ),
              );
            },
          ),
        ],
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildPaymentChip(BuildContext context, String label, String value, TableOrderViewProvider viewProvider) {
    final bool isSelected = viewProvider.paymentType == value;
    return Expanded(
      child: InkWell(
        onTap: () => viewProvider.setPaymentType(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.lightGrey),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  Future<void> _printKitchenTicketFromSheet({
    required BuildContext context,
    required MenuProvider menuProvider,
    required String note,
  }) {
    final orderProvider = Provider.of<TableOrderProvider>(context, listen: false);
    // Expand each customized instance into its own ticket entry (same split as
    // the bill).
    final items = orderProvider.buildKitchenItems(tableId, menuProvider.tableProducts);

    final int tNo = int.tryParse(tableId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final pending = Provider.of<OrderProvider>(context, listen: false).pendingTables.where((t) => t.tableNo == tNo);

    return KitchenPrint.printTicket(
      context,
      trackingKey: KitchenPrint.tableKey(tableId),
      tokenNumber: tableId,
      sessionId: pending.isEmpty ? null : pending.first.createdAt?.toIso8601String(),
      orderCreatedAt: pending.isNotEmpty ? pending.first.createdAt : DateTime.now(),
      items: items,
      note: note,
      customerName: orderProvider.getCustomerName(tableId),
      customerMobile: orderProvider.getCustomerMobile(tableId),
    );
  }

  // Cancel the whole order: removes every item and clears the table. If the
  // order has already auto-synced to the server as a pending dine-in order, it
  // is cancelled there too so the table frees up and it won't reappear.
  Future<void> _handleCancelOrder(
    BuildContext context,
    TableOrderProvider orderProvider, {
    VoidCallback? onDismiss,
  }) async {
    final outerContext = context;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text('torder.cancel_order'.tr()),
        content: Text('torder.cancel_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.dismiss'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('torder.cancel_order'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ownerProvider = Provider.of<OrderProvider>(outerContext, listen: false);
    final int tNo = int.tryParse(tableId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    String? findServerOrderId() {
      for (final t in ownerProvider.pendingTables) {
        if (t.tableNo == tNo && t.orderId.isNotEmpty) return t.orderId;
      }
      return null;
    }

    // Look in the cached pending tables; if nothing is found, refresh once in
    // case the list is stale, then look again before giving up.
    String? serverOrderId = findServerOrderId();
    if (serverOrderId == null) {
      await ownerProvider.fetchPendingTables();
      serverOrderId = findServerOrderId();
    }
    if (serverOrderId != null) {
      await ownerProvider.updateOrderStatus(serverOrderId, OrderStatus.cancelled);
    }

    // Remove items and clear the table locally.
    orderProvider.clearCart(tableId);
    Provider.of<TableOrderViewProvider>(outerContext, listen: false).resetInit();

    if (!outerContext.mounted) return;
    onDismiss?.call();
    ownerProvider.fetchDashboard();
    ownerProvider.fetchPendingTables();

    CustomSnackbar.show(outerContext, message: 'torder.order_cancelled'.tr(), isError: false);
    if (outerContext.mounted) Navigator.pop(outerContext);
  }
}
