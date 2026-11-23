import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/resource.dart';
import '../../../models/category_model.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/menu_provider.dart';
import '../../../providers/add_menu_item_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../core/utils/custom_snackbar.dart';

class AddMenuItemDialog extends StatelessWidget {
  final MenuItemModel? item;

  const AddMenuItemDialog({super.key, this.item});

  bool get isEdit => item != null;

  void _showImageSourceSheet(BuildContext context, AddMenuItemProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'menu.select_image_source'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(context, provider, Icons.camera_alt_outlined, 'form.camera'.tr(), ImageSource.camera),
                _buildSourceOption(context, provider, Icons.photo_library_outlined, 'form.gallery'.tr(), ImageSource.gallery),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(BuildContext context, AddMenuItemProvider provider, IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(context, provider, source);
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryBlue, size: 28.sp),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, AddMenuItemProvider provider, ImageSource source) async {
    final picker = ImagePicker();
    try {
      if (Platform.isAndroid && source == ImageSource.gallery) {
        final LostDataResponse response = await picker.retrieveLostData();
        if (response.file != null) {
          final file = File(response.file!.path);
          if (await file.exists()) {
            provider.setImage(file);
            return;
          }
        }
      }

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image == null) return;

      final File imageFile = File(image.path);
      if (!await imageFile.exists()) throw Exception('menu.image_not_found'.tr());

      provider.setImage(imageFile);
    } on PlatformException catch (e) {
      debugPrint('Platform Error: ${e.code}');
      String message = 'menu.failed_pick_image'.tr();
      if (e.code == 'no_valid_image_uri') {
        message = 'Unable to access this image. Please select another image.';
      }
      if (context.mounted) {
        CustomSnackbar.show(context, message: message);
      }
    } catch (e) {
      debugPrint('Image Picker Error: $e');
      if (context.mounted) {
        CustomSnackbar.show(context, message: 'menu.image_select_err'.tr());
      }
    }
  }

  void _showAddCategoryDialog(BuildContext context, AddMenuItemProvider addMenuItemProvider) {
    final nameCtrl = TextEditingController();
    final provider = Provider.of<MenuProvider>(context, listen: false);
    final picker = ImagePicker();
    final outerContext = context;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        File? categoryImage;

        void pickCategoryImage(StateSetter setDialogState) {
          showModalBottomSheet(
            context: ctx,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
            builder: (sheetCtx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 12.h),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: Text('form.camera'.tr()),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      final picked = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 80,
                      );
                      if (picked != null) setDialogState(() => categoryImage = File(picked.path));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: Text('form.gallery'.tr()),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 80,
                      );
                      if (picked != null) setDialogState(() => categoryImage = File(picked.path));
                    },
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          );
        }

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            scrollable: true,
            title: Text('menu.add_category'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => pickCategoryImage(setDialogState),
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: categoryImage != null
                        ? Image.file(categoryImage!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 24.sp, color: AppColors.primaryBlue),
                              SizedBox(height: 4.h),
                              Text('form.photo'.tr(), style: TextStyle(fontSize: 10.sp, color: AppColors.primaryBlue)),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'menu.category_name'.tr(),
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
                onPressed: isLoading
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (categoryImage == null) {
                          CustomSnackbar.show(outerContext, message: 'menu.category_image_required'.tr());
                          return;
                        }
                        if (name.isEmpty) {
                          CustomSnackbar.show(outerContext, message: 'menu.category_name_required'.tr());
                          return;
                        }
                        setDialogState(() => isLoading = true);
                        final result = await provider.addCategory(name: name, image: categoryImage);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (result is Success) {
                          final cats = provider.categories;
                          final match = cats.lastWhere(
                            (c) => c.name.toLowerCase() == name.toLowerCase(),
                            orElse: () => cats.last,
                          );
                          addMenuItemProvider.setCategoryId(match.id);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('common.add'.tr(), style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryRow(BuildContext context, AddMenuItemProvider addMenuItemProvider, List<CategoryModel> categories) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'menu.category_req'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: addMenuItemProvider.selectedCategoryId,
                    dropdownColor: Theme.of(context).cardColor,
                    hint: Text(
                      'menu.select_category'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13.sp,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
                    items: categories
                        .map((cat) => DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => addMenuItemProvider.setCategoryId(val),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () => _showAddCategoryDialog(context, addMenuItemProvider),
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.add, color: AppColors.primaryBlue, size: 22.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildGstSection(BuildContext context, AddMenuItemProvider provider) {
    const rates = [0.0, 5.0, 12.0, 18.0, 28.0];

    return Container(
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
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 18.sp, color: AppColors.primaryBlue),
                  SizedBox(width: 8.w),
                  Text(
                    'menu.gst_applicable'.tr(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              Switch(
                value: provider.isGstApplicable,
                activeColor: AppColors.primaryBlue,
                onChanged: (v) => provider.setGstApplicable(v),
              ),
            ],
          ),
          if (provider.isGstApplicable) ...[
            SizedBox(height: 10.h),
            Text(
              'menu.gst_rate'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: provider.selectedGstRate,
                  dropdownColor: Theme.of(context).cardColor,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
                  items: rates
                      .map((rate) => DropdownMenuItem<double>(
                            value: rate,
                            child: Text(
                              '${rate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) provider.setGstRate(val);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Consumer<AddMenuItemProvider>(
            builder: (context, provider, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isEdit ? 'menu.update_item'.tr() : 'menu.add_new_item'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.cancel_outlined, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Center(
                    child: GestureDetector(
                      onTap: () => _showImageSourceSheet(context, provider),
                      child: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                          image: provider.selectedImage != null
                              ? DecorationImage(image: FileImage(provider.selectedImage!), fit: BoxFit.cover)
                              : item?.image != null
                                  ? DecorationImage(
                                      image: NetworkImage('${ApiConstants.imageBaseUrl}${item!.image!}'),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: provider.selectedImage == null && item?.image == null
                            ? Icon(Icons.add_a_photo_outlined, color: AppColors.primaryBlue, size: 30.sp)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(label: 'menu.item_name'.tr(), hint: 'menu.item_name_hint2'.tr(), controller: provider.nameController),
                  SizedBox(height: 12.h),
                  Consumer<MenuProvider>(
                    builder: (context, menuProvider, _) => _buildCategoryRow(context, provider, menuProvider.categories),
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(label: 'menu.description'.tr(), hint: 'menu.description_hint'.tr(), controller: provider.descController),
                  SizedBox(height: 12.h),
                  if (provider.selectedUnit != PriceUnit.plate)
                    CustomTextField(
                      label: 'menu.base_price'.tr(),
                      hint: '0.00',
                      controller: provider.priceController,
                      keyboardType: TextInputType.number,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'menu.half_price'.tr(),
                            hint: '0.00',
                            controller: provider.halfPriceController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: CustomTextField(
                            label: 'menu.full_price'.tr(),
                            hint: '0.00',
                            controller: provider.fullPriceController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 16.h),
                  Text(
                    'menu.pricing_unit'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(child: _buildUnitOption(provider, 'Qty', PriceUnit.quantity, Icons.inventory_2_outlined)),
                      SizedBox(width: 8.w),
                      Expanded(child: _buildUnitOption(provider, 'Kg', PriceUnit.weight, Icons.scale_outlined)),
                      SizedBox(width: 8.w),
                      Expanded(child: _buildUnitOption(provider, 'menu.plate'.tr(), PriceUnit.plate, Icons.local_dining)),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildGstSection(context, provider),
                  SizedBox(height: 24.h),
                  Consumer<MenuProvider>(
                    builder: (context, menuProvider, child) {
                      return PrimaryButton(
                        label: isEdit ? 'menu.update_item'.tr() : 'menu.add_item'.tr(),
                        onPressed: () => _onSavePressed(context, provider),
                        isLoading: isEdit ? menuProvider.updateItemResource is Loading : menuProvider.addItemResource is Loading,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onSavePressed(BuildContext context, AddMenuItemProvider provider) async {
    final name = provider.nameController.text.trim();
    if (name.isEmpty) {
      CustomSnackbar.show(context, message: 'form.item_name_err'.tr());
      return;
    }

    if (provider.selectedCategoryId == null) {
      CustomSnackbar.show(context, message: 'menu.select_category_err'.tr());
      return;
    }

    if (provider.selectedImage == null && !isEdit) {
      CustomSnackbar.show(context, message: 'menu.select_image_err'.tr());
      return;
    }

    if (provider.selectedUnit == PriceUnit.plate) {
      final halfPriceText = provider.halfPriceController.text.trim();
      final fullPriceText = provider.fullPriceController.text.trim();

      if (fullPriceText.isEmpty) {
        CustomSnackbar.show(context, message: 'menu.full_price_err'.tr());
        return;
      }

      if (halfPriceText.isNotEmpty) {
        final halfPrice = double.tryParse(halfPriceText) ?? 0;
        final fullPrice = double.tryParse(fullPriceText) ?? 0;
        if (halfPrice >= fullPrice) {
          CustomSnackbar.show(context, message: 'menu.half_less_err'.tr());
          return;
        }
      }
    } else {
      if (provider.priceController.text.trim().isEmpty) {
        CustomSnackbar.show(context, message: 'menu.price_err'.tr());
        return;
      }
    }

    String unitParam = 'NOS';
    if (provider.selectedUnit == PriceUnit.weight) {
      unitParam = 'KG';
    } else if (provider.selectedUnit == PriceUnit.plate) {
      unitParam = 'menu.plate'.tr();
    }

    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    final Resource<MenuItemModel> result;
    if (isEdit) {
      result = await menuProvider.updateMenuItem(
        id: item!.id,
        categoryId: provider.selectedCategoryId!,
        image: provider.selectedImage,
        name: name,
        unit: unitParam,
        price: (provider.selectedUnit == PriceUnit.plate ? provider.fullPriceController.text : provider.priceController.text).trim(),
        description: provider.descController.text.trim(),
        halfPrice: provider.selectedUnit == PriceUnit.plate ? provider.halfPriceController.text.trim() : null,
        gstApplicable: provider.isGstApplicable,
        gstRate: provider.selectedGstRate,
      );
    } else {
      result = await menuProvider.addMenuItem(
        image: provider.selectedImage!,
        categoryId: provider.selectedCategoryId!,
        name: name,
        unit: unitParam,
        price: (provider.selectedUnit == PriceUnit.plate ? provider.fullPriceController.text : provider.priceController.text).trim(),
        description: provider.descController.text.trim(),
        halfPrice: provider.selectedUnit == PriceUnit.plate ? provider.halfPriceController.text.trim() : null,
        gstApplicable: provider.isGstApplicable,
        gstRate: provider.selectedGstRate,
      );
    }

    if (result is Success) {
      if (context.mounted) {
        Navigator.pop(context, true);
        CustomSnackbar.show(
          context,
          message: isEdit ? 'menu.item_updated'.tr() : 'menu.item_added'.tr(),
          isError: false,
        );
      }
    } else {
      if (context.mounted) {
        CustomSnackbar.show(context, message: (result as Error).failure?.message ?? 'menu.failed_add'.tr());
      }
    }
  }

  Widget _buildUnitOption(AddMenuItemProvider provider, String label, PriceUnit unit, IconData icon) {
    bool isSelected = provider.selectedUnit == unit;
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return GestureDetector(
          onTap: () => provider.setUnit(unit),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : theme.dividerColor.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primaryBlue : theme.textTheme.bodySmall?.color,
                  size: 18.sp,
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primaryBlue : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
