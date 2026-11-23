import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/resource.dart';
import '../../core/utils/custom_snackbar.dart';
import '../../core/utils/kitchen_print.dart';
import '../../core/services/printer_service.dart';
import '../../models/order_model.dart';
import '../../models/table_product_list_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/table_order_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../presentation/widgets/api_widgets.dart';

/// In-app POS screen for placing takeaway orders.
/// Mirrors the dine-in product-selection layout but is not tied to a table;
/// placed orders are created as pending 'takeaway' orders and appear in the
/// Takeaway section of the dashboard.
class PosOrderScreen extends StatefulWidget {
  const PosOrderScreen({super.key});

  @override
  State<PosOrderScreen> createState() => _PosOrderScreenState();
}

class _PosOrderScreenState extends State<PosOrderScreen> {
  static const String _sid = TableOrderProvider.posSessionId;
  final TextEditingController _searchController = TextEditingController();

  // Cart form state (shared by the portrait bottom sheet and the landscape
  // right-side panel, so it must persist on the State rather than in the sheet).
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _upiAmtCtrl = TextEditingController();
  final TextEditingController _cashAmtCtrl = TextEditingController();
  // Cash tendered by the customer (to compute "Return to Customer").
  final TextEditingController _cashReceivedCtrl = TextEditingController();
  String? _selectedPayment = 'upi';
  bool _cartOpen = false; // landscape right-side panel open?
  int _lastItemCount = 0; // for auto-opening the panel when an item is added

  @override
  void initState() {
    super.initState();
    final menuProvider = context.read<MenuProvider>();
    final orderProvider = context.read<TableOrderProvider>();
    Future.microtask(() async {
      orderProvider.setCategory(null);
      orderProvider.setSearch('');
      menuProvider.fetchTableProducts(forceRefresh: true);
      // Restore the server-side draft (an in-progress take-away order saved
      // before "Place Order") so it survives an app/device restart.
      await orderProvider.restorePosDraft();
      if (!mounted) return;
      _nameCtrl.text = orderProvider.getCustomerName(_sid);
      _mobileCtrl.text = orderProvider.getCustomerMobile(_sid);
      _noteCtrl.text = orderProvider.getOrderNote(_sid);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _noteCtrl.dispose();
    _upiAmtCtrl.dispose();
    _cashAmtCtrl.dispose();
    _cashReceivedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Column(
            children: [
              Text(
                'pos.title'.tr(),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Text(
                'pos.new_takeaway'.tr(),
                style: TextStyle(fontSize: 10.sp, color: AppColors.grey),
              ),
            ],
          ),
          centerTitle: true,
          // Cart lives in a right-side panel only in landscape; the toggle icon
          // is shown only then (portrait uses the bottom bar + bottom sheet).
          actions: isLandscape ? [_buildCartToggleAction()] : null,
        ),
        body: Consumer2<MenuProvider, TableOrderProvider>(
          builder: (context, menuProvider, orderProvider, child) {
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
            final int itemCount = orderProvider.getCart(_sid).entries.where((e) => e.value > 0).length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (isLandscape && itemCount > _lastItemCount && itemCount > 0 && !_cartOpen) {
                setState(() => _cartOpen = true);
              }
              _lastItemCount = itemCount;
            });

            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchBar(orderProvider),
                      Expanded(
                        child: Row(
                          children: [
                            _buildCategorySidebar(menuProvider.tableCategories, orderProvider),
                            Expanded(child: _buildItemGrid(menuProvider.tableProducts, orderProvider)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLandscape && _cartOpen)
                  SizedBox(width: cartWidth, child: _buildCartPanel()),
              ],
            );
          },
        ),
        bottomNavigationBar: isLandscape ? null : _buildCartBar(),
      ),
    );
  }

  // App-bar icon that opens/closes the right-side cart panel in landscape.
  Widget _buildCartToggleAction() {
    return Consumer2<MenuProvider, TableOrderProvider>(
      builder: (context, menuProvider, orderProvider, _) {
        final int itemCount = orderProvider.getCart(_sid).entries.where((e) => e.value > 0).length;
        return Padding(
          padding: EdgeInsets.only(right: 6.w),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'order.order_items'.tr(),
                onPressed: () => setState(() => _cartOpen = !_cartOpen),
                icon: Icon(
                  _cartOpen ? Icons.shopping_cart : Icons.shopping_cart_outlined,
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

  Widget _buildSearchBar(TableOrderProvider orderProvider) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: TextField(
        controller: _searchController,
        onChanged: orderProvider.setSearch,
        decoration: InputDecoration(
          hintText: 'order.search_items'.tr(),
          prefixIcon: Icon(Icons.search, size: 20.sp, color: AppColors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 18.sp),
                  onPressed: () {
                    _searchController.clear();
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

  Widget _buildCategorySidebar(List<TableCategoryModel> categories, TableOrderProvider orderProvider) {
    return Container(
      width: 100.w,
      color: Colors.white,
      child: ListView.builder(
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final bool isAll = index == 0;
          final TableCategoryModel? cat = isAll ? null : categories[index - 1];
          final String name = isAll ? 'common.all'.tr() : cat!.name;
          final bool selected = isAll ? orderProvider.selectedCategoryId == null : orderProvider.selectedCategoryId == cat!.id;
          return InkWell(
            onTap: () => orderProvider.setCategory(isAll ? null : cat!.id),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBlue.withValues(alpha: 0.12) : Colors.transparent,
                border: Border(left: BorderSide(color: selected ? AppColors.primaryBlue : Colors.transparent, width: 3.5)),
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? AppColors.primaryBlue : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemGrid(List<TableProductModel> items, TableOrderProvider orderProvider) {
    final search = orderProvider.searchText.trim().toLowerCase();
    final filtered = items.where((i) {
      if (search.isNotEmpty) {
        return i.name.toLowerCase().contains(search);
      }
      return orderProvider.selectedCategoryId == null || i.categoryId == orderProvider.selectedCategoryId;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'order.no_items_found'.tr(),
          style: TextStyle(color: AppColors.grey, fontSize: 13.sp),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(10.w),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180.w,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 0.86,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildItemCard(filtered[index], orderProvider),
    );
  }

  void _showNewDishDialog(
    BuildContext context,
    TableProductModel item,
    TableOrderProvider orderProvider,
  ) {
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
                      _sid,
                      item.id,
                      dishName,
                      additionalPrice: price - basePrice,
                    );

                    orderProvider.updateQuantity(
                      _sid,
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
                        _sid,
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
                  orderProvider.updateQuantity(_sid, item.id, 0, allProducts: menuProvider.tableProducts);
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
                      orderProvider.updateQuantity(_sid, item.id, w, allProducts: menuProvider.tableProducts);
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

  Widget _buildItemCard(TableProductModel item, TableOrderProvider orderProvider) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final double qty = orderProvider.getCart(_sid)[item.id] ?? 0;
    final String unit = item.unit?.toUpperCase() ?? 'NOS';
    final selectedVariant = orderProvider.getSelectedVariant(_sid, item.id);
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
              orderProvider.updateQuantity(_sid, item.id, qty + 1.0, allProducts: menuProvider.tableProducts);
            }
          } else if (item.isCustomizable) {
            // Subcategory item: re-open the customization dialog on every add.
            _showCustomizationDialog(context, item, orderProvider);
          } else if (unit == 'KG') {
            _showWeightPicker(context, item, qty, orderProvider);
          } else if (qty == 0) {
            orderProvider.updateQuantity(_sid, item.id, 1.0, allProducts: menuProvider.tableProducts);
          } else {
            final bool hasHalfPrice = (double.tryParse(item.halfPrice ?? '') ?? 0) > 0;
            final double step = hasHalfPrice ? 0.5 : 1.0;
            orderProvider.updateQuantity(_sid, item.id, qty + step, allProducts: menuProvider.tableProducts);
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '₹${item.price}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                ),
                if (qty > 0)
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 6.w),
                      child: Text(
                        '${'pos.qty'.tr()}: ${_fmtQty(qty, unit)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ),
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
                          orderProvider.updateQuantity(_sid, item.id, 1.0, allProducts: menuProvider.tableProducts);
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
                : Container(
                    height: 28.h,
                    decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(8.r)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stepBtn(
                          Icons.remove,
                          () {
                            if (unit == 'KG') {
                              orderProvider.updateQuantity(_sid, item.id, 0, isExplicitRemove: true, allProducts: menuProvider.tableProducts);
                            } else {
                              final bool hasHalfPrice = (double.tryParse(item.halfPrice ?? '') ?? 0) > 0;
                              if (hasHalfPrice) {
                                if (qty <= 1.0) {
                                  orderProvider.updateQuantity(_sid, item.id, 0, isExplicitRemove: true, allProducts: menuProvider.tableProducts);
                                } else {
                                  orderProvider.updateQuantity(_sid, item.id, qty - 0.5, allProducts: menuProvider.tableProducts);
                                }
                              } else {
                                orderProvider.updateQuantity(_sid, item.id, qty - 1.0, isExplicitRemove: qty <= 1.0, allProducts: menuProvider.tableProducts);
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
                              orderProvider.updateQuantity(_sid, item.id, qty + stepVal, allProducts: menuProvider.tableProducts);
                            }
                          },
                        ),
                      ],
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

  Widget _buildCartBar() {
    return Consumer2<MenuProvider, TableOrderProvider>(
      builder: (context, menuProvider, orderProvider, child) {
        final cart = orderProvider.getCart(_sid);
        if (cart.isEmpty) return const SizedBox.shrink();

        final int count = cart.length;
        final bool gstEnabled = Provider.of<SettingsProvider>(context, listen: false).isGstEnabled;
        final double total = orderProvider
            .computeBillTotals(_sid, menuProvider.tableProducts, gstEnabled: gstEnabled)
            .grandTotal;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _openCartSheet(orderProvider, menuProvider),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'order.total_items_n'.tr(namedArgs: {'n': '$count'}),
                        style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                      ),
                      Text(
                        '${'common.total'.tr()} - ₹${total.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 26.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: orderProvider.isLoading ? null : () => _openCartSheet(orderProvider, menuProvider),
                    icon: orderProvider.isLoading
                        ? SizedBox(
                            width: 16.sp,
                            height: 16.sp,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.receipt_long, size: 18.sp),
                    label: Text(orderProvider.isLoading ? 'pos.placing'.tr() : 'pos.view_place'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Cancel the POS order: discard every item from the (not-yet-placed) cart and
  // close the sheet. Nothing has been sent to the server yet, so this just
  // clears the local draft.
  Future<void> _handleCancelPosOrder(BuildContext context, TableOrderProvider orderProvider, {VoidCallback? onDismiss}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text('order.cancel_order'.tr()),
        content: Text('pos.cancel_confirm'.tr()),
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
            child: Text('order.cancel_order'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    orderProvider.clearCart(_sid);
    // Also discard the server-side draft so it isn't restored on next launch.
    orderProvider.cancelPosDraft();
    _nameCtrl.clear();
    _mobileCtrl.clear();
    _noteCtrl.clear();
    onDismiss?.call();
    if (mounted) {
      CustomSnackbar.show(context, message: 'pos.order_cancelled'.tr(), isError: false);
    }
  }

  // The POS cart contents, shared by the portrait bottom sheet and the
  // landscape right-side panel. [onDismiss] closes whichever is presenting it.
  Widget _posCartInner(BuildContext screenContext, {required VoidCallback onDismiss}) {
    return Consumer2<MenuProvider, TableOrderProvider>(
      builder: (context, menuProvider, orderProvider, child) {
        // Each customized instance shows as its own saved line (with its
        // sub-category), matching the bill and the order-details sheet.
        final lines = orderProvider.buildDisplayLines(_sid, menuProvider.tableProducts);

        // GST-aware totals (grand total is what the customer pays).
        final bool gstEnabled = Provider.of<SettingsProvider>(context, listen: false).isGstEnabled;
        final totals = orderProvider.computeBillTotals(_sid, menuProvider.tableProducts, gstEnabled: gstEnabled);
        final double total = totals.grandTotal;

        void changeQty(TableProductModel p, double newQty) {
          orderProvider.updateQuantity(_sid, p.id, newQty, isExplicitRemove: newQty <= 0);
          setState(() {});
        }

        final bool hasItems = lines.isNotEmpty;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('order.order_items'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                  const Spacer(),
                  Text('${lines.length} item${lines.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 12.sp, color: AppColors.grey)),
                  SizedBox(width: 6.w),
                  InkWell(onTap: onDismiss, child: Icon(Icons.close, size: 20.sp, color: Colors.black)),
                ],
              ),
              SizedBox(height: 10.h),
              if (!hasItems)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Center(child: Text('order.no_items_found'.tr(), style: TextStyle(color: AppColors.grey, fontSize: 13.sp))),
                )
              else ...[
                ...lines.map((l) {
                  final TableProductModel p = l.product;
                  final double qty = l.qty;
                  final String unit = p.unit?.toUpperCase() ?? 'NOS';
                  final double step = unit == 'KG' ? 0.5 : 1.0;
                  final String? note = l.note;
                  // A customized item (it carries a sub-category) is shown per
                  // instance and is managed from the menu/customization dialog,
                  // so it has no qty stepper or delete button here. Plain items
                  // keep the interactive stepper + remove button.
                  final bool isCustomized = orderProvider.itemHasCustomization(_sid, p.id);

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                              if (note != null && note.isNotEmpty)
                                Text(note, style: TextStyle(fontSize: 11.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.bold))
                              else
                                Text('₹${p.price}  ·  ${unit.toLowerCase()}', style: TextStyle(fontSize: 11.sp, color: AppColors.grey)),
                            ],
                          ),
                        ),
                        if (isCustomized)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Text(_fmtQty(qty, unit), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                          )
                        else ...[
                          _sheetStep(Icons.remove, () => changeQty(p, qty - step)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Text(_fmtQty(qty, unit), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                          ),
                          _sheetStep(Icons.add, () => changeQty(p, qty + step)),
                        ],
                        SizedBox(width: 10.w),
                        SizedBox(
                          width: 56.w,
                          child: Text('₹${l.lineTotal.toStringAsFixed(0)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        ),
                        // A customized item can't be deleted from the order, so
                        // hide its remove button.
                        if (!isCustomized)
                          IconButton(
                            onPressed: () => changeQty(p, 0),
                            icon: Icon(Icons.close, size: 16.sp, color: AppColors.errorRed),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.only(left: 6.w),
                          )
                        else
                          SizedBox(width: 22.w),
                      ],
                    ),
                  );
                }),
                Divider(height: 24.h),
                if (totals.gst > 0) ...[
                  _billRow('order.subtotal'.tr(), totals.subtotal),
                  SizedBox(height: 4.h),
                  _billRow('CGST', totals.cgst),
                  SizedBox(height: 4.h),
                  _billRow('SGST', totals.sgst),
                  SizedBox(height: 6.h),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('common.total'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                    Text('₹${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Text('pos.customer_details'.tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(width: 6.w),
                    Text('common.optional'.tr(), style: TextStyle(fontSize: 11.sp, color: AppColors.grey)),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _sheetField(_nameCtrl, 'pos.customer_name'.tr(), Icons.person_outline, textCapitalization: TextCapitalization.words)),
                    SizedBox(width: 8.w),
                    Expanded(child: _sheetField(_mobileCtrl, 'pos.mobile_number'.tr(), Icons.phone_outlined, keyboard: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)])),
                    SizedBox(width: 8.w),
                    Expanded(child: _sheetField(_noteCtrl, 'pos.order_note'.tr(), Icons.note_alt_outlined)),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Text('pay.payment_method'.tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(width: 6.w),
                    Text('common.optional'.tr(), style: TextStyle(fontSize: 11.sp, color: AppColors.grey)),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _payChip('pay.cash'.tr(), 'cash', _selectedPayment, () {
                      setState(() => _selectedPayment = _selectedPayment == 'cash' ? null : 'cash');
                    }),
                    SizedBox(width: 8.w),
                    _payChip('pay.upi'.tr(), 'upi', _selectedPayment, () {
                      setState(() => _selectedPayment = _selectedPayment == 'upi' ? null : 'upi');
                    }),
                    SizedBox(width: 8.w),
                    _payChip('pay.part_payment'.tr(), 'part_payment', _selectedPayment, () {
                      setState(() => _selectedPayment = _selectedPayment == 'part_payment' ? null : 'part_payment');
                    }),
                  ],
                ),
                if (_selectedPayment == 'part_payment') ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(child: _sheetField(_upiAmtCtrl, 'pos.upi_amount'.tr(), Icons.account_balance_wallet_outlined, keyboard: TextInputType.number, onChanged: (v) => _autoFillOther(total, v, _cashAmtCtrl))),
                      SizedBox(width: 10.w),
                      Expanded(child: _sheetField(_cashAmtCtrl, 'pos.cash_amount'.tr(), Icons.payments_outlined, keyboard: TextInputType.number, onChanged: (v) => _autoFillOther(total, v, _upiAmtCtrl))),
                    ],
                  ),
                ],
                // Cash: enter the amount tendered and show the change due.
                if (_selectedPayment == 'cash') ...[
                  SizedBox(height: 10.h),
                  _sheetField(_cashReceivedCtrl, 'pay.amount_received'.tr(), Icons.payments_outlined, keyboard: TextInputType.number, onChanged: (_) => setState(() {})),
                  _cashReturnRow(total),
                ],
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: !hasItems
                            ? null
                            : () {
                                // Expand each customized instance into its own
                                // ticket entry (same split as the bill).
                                final items = orderProvider.buildKitchenItems(_sid, menuProvider.tableProducts);
                                if (items.isEmpty) return;
                                KitchenPrint.printTicket(
                                  screenContext,
                                  trackingKey: 'pos-${DateTime.now().millisecondsSinceEpoch}',
                                  tokenNumber: '-',
                                  items: items,
                                  note: _noteCtrl.text.trim(),
                                  orderType: 'takeaway',
                                  customerName: _nameCtrl.text.trim(),
                                  customerMobile: _mobileCtrl.text.trim(),
                                );
                              },
                        icon: Icon(Icons.print_outlined, size: 16.sp),
                        label: Text('order.kitchen_print'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleCancelPosOrder(screenContext, orderProvider, onDismiss: onDismiss),
                        icon: Icon(Icons.delete_outline, size: 16.sp),
                        label: Text('order.cancel_order'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: const BorderSide(color: AppColors.errorRed),
                          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: !hasItems
                            ? null
                            : () {
                                double? upiAmt;
                                double? cashAmt;
                                if (_selectedPayment == 'part_payment') {
                                  upiAmt = double.tryParse(_upiAmtCtrl.text.trim()) ?? 0;
                                  cashAmt = double.tryParse(_cashAmtCtrl.text.trim()) ?? 0;
                                  if ((upiAmt + cashAmt) > total) {
                                    CustomSnackbar.show(screenContext, message: 'pos.split_exceeds'.tr());
                                    return;
                                  }
                                }
                                orderProvider.setCustomerDetails(
                                  _sid,
                                  name: _nameCtrl.text.trim(),
                                  mobile: _mobileCtrl.text.trim(),
                                  note: _noteCtrl.text.trim(),
                                );
                                onDismiss();
                                _placeOrder(orderProvider, menuProvider, _selectedPayment, upiAmt, cashAmt);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text(
                          '${'pos.place_order'.tr()} · ₹${total.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Landscape: POS cart docked on the right.
  Widget _buildCartPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(left: BorderSide(color: AppColors.lightGrey)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(-4, 0))],
      ),
      child: SafeArea(
        child: _posCartInner(context, onDismiss: () => setState(() => _cartOpen = false)),
      ),
    );
  }

  // Portrait: open the POS cart as a bottom sheet.
  void _openCartSheet(TableOrderProvider orderProvider, MenuProvider menuProvider) {
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
                child: _posCartInner(context, onDismiss: () => Navigator.pop(sheetContext)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetStep(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7.r)),
        child: Icon(icon, size: 15.sp, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _payChip(String label, String value, String? selected, VoidCallback onTap) {
    final bool isSel = selected == value;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: isSel ? AppColors.primaryBlue : AppColors.lightGrey),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

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

  // Shows "Return to Customer" = cash tendered - bill total, once an amount is entered.
  Widget _cashReturnRow(double total) {
    final received = double.tryParse(_cashReceivedCtrl.text.trim()) ?? 0;
    if (received <= 0) return const SizedBox.shrink();
    final double change = received - total;
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Container(
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
      ),
    );
  }

  // Part payment: type one amount and the remaining balance auto-fills the other.
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

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboard,
      TextCapitalization textCapitalization = TextCapitalization.none,
      List<TextInputFormatter>? inputFormatters,
      ValueChanged<String>? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18.sp, color: AppColors.grey),
        isDense: true,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _placeOrder(TableOrderProvider orderProvider, MenuProvider menuProvider,
      [String? paymentType, double? upiAmount, double? cashAmount]) async {
    // Capture what the local print needs before the async gap.
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final String? userName = Provider.of<OrderProvider>(context, listen: false).dashboardData?.userName;
    final String? gstin = settings.gstin.trim().isNotEmpty ? settings.gstin : null;

    final result = await orderProvider.savePosOrder(
      allProducts: menuProvider.tableProducts,
      paymentType: paymentType,
      upiAmount: upiAmount,
      cashAmount: cashAmount,
      gstEnabled: settings.isGstEnabled,
    );
    if (!mounted) return;
    if (result is Success<OrderModel>) {
      // Print the bill locally the moment the order is placed, so printing does
      // NOT depend on the realtime socket being connected. The print is keyed by
      // the server order id, and the realtime auto-print path dedups against the
      // same id (PrinterService._printedReceiptIds), so no duplicate is produced
      // whichever path reaches the printer first.
      final order = result.data;
      if (order != null && order.id.isNotEmpty) {
        PrinterService().printReceiptOnce(order, userName: userName, gstin: gstin).catchError((e) {
          debugPrint('Local bill print error: $e');
          return false;
        });
      }
      // Don't call fetchDashboard() here: a non-realtime fetch would mark the
      // order "seen" and could stop the realtime handler from treating it as new.
      CustomSnackbar.show(context, message: 'pos.order_placed'.tr(), isError: false);
      Navigator.pop(context);
    } else {
      CustomSnackbar.show(
        context,
        message: result is Error ? (result.failure?.message ?? 'pos.failed_place'.tr()) : 'pos.failed_place'.tr(),
      );
    }
  }
}
