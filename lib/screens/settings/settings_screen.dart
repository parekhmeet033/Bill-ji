import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lineless/core/theme/app_colors.dart';
import 'package:lineless/presentation/providers/auth_provider.dart';
import 'package:lineless/providers/order_provider.dart';
import 'package:lineless/screens/auth/login_screen.dart';
import 'package:lineless/core/utils/custom_snackbar.dart';
import 'package:lineless/models/shop_settings_model.dart';
import 'package:lineless/providers/theme_provider.dart';
import 'package:lineless/providers/settings_provider.dart';
import 'package:lineless/core/services/printer_service.dart';
import 'package:lineless/core/utils/resource.dart';
import 'package:lineless/providers/navigation_provider.dart';
import 'package:lineless/screens/settings/printer_settings_screen.dart';
import 'package:lineless/screens/settings/kitchen_print_items_screen.dart';
import 'package:lineless/screens/settings/support_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lineless/core/localization/locale_service.dart';
import 'package:lineless/widgets/language_selector.dart';

import '../../providers/printer_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _tableCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _loadSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _tableCountController.text = authProvider.tableCount.toString();
    await authProvider.fetchShopSettings();

    if (mounted) {
      settingsProvider.init(authProvider);

      if (authProvider.shopSettings != null) {
        String mode = authProvider.shopSettings!.oprationModeStatus;
        authProvider.setRestaurantMode(mode);
        authProvider.setTableCount(authProvider.shopSettings!.numberOfTables);
        _tableCountController.text = authProvider.shopSettings!.numberOfTables.toString();
      }
    }
  }

  void _onAlertToneToggle(bool value) {
    if (!value) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('settings.stop_alert_title'.tr()),
          content: Text('settings.stop_alert_msg'.tr()),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateAlertTone(false);
              },
              child: Text(
                'common.stop'.tr(),
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      _updateAlertTone(true);
    }
  }

  void _updateAlertTone(bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await authProvider.setAlertToneStatus(value);
    settingsProvider.setAlertTone(value);
  }

  void _onNotificationToggle(bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await authProvider.setNotificationStatus(value);
    settingsProvider.setNotification(value);
  }

  Future<void> _updateSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Validation: If GST is enabled, business details MUST be filled in.
    if (settingsProvider.isGstEnabled) {
      if (settingsProvider.gstin.trim().isEmpty) {
        CustomSnackbar.show(context, message: 'settings.err_gstin'.tr());
        return;
      }
      if (settingsProvider.legalBusinessName.trim().isEmpty) {
        CustomSnackbar.show(context, message: 'settings.err_legal'.tr());
        return;
      }
      if (settingsProvider.businessAddress.trim().isEmpty) {
        CustomSnackbar.show(context, message: 'settings.err_address'.tr());
        return;
      }
      if (settingsProvider.state.trim().isEmpty) {
        CustomSnackbar.show(context, message: 'settings.err_state'.tr());
        return;
      }
      if (settingsProvider.stateCode.trim().isEmpty) {
        CustomSnackbar.show(context, message: 'settings.err_state_code'.tr());
        return;
      }
    }

    final success = await settingsProvider.saveSettings(authProvider, orderProvider);

    if (mounted) {
      if (success) {
        CustomSnackbar.show(context, message: 'settings.updated_success'.tr(), isError: false);
      } else {
        CustomSnackbar.show(context, message: authProvider.settingsResource.failure?.message ?? 'settings.update_failed'.tr());
      }
    }
  }

  Future<void> _selectTime(BuildContext context, String currentVal, Function(String) onSelected) async {
    final parts = currentVal.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      onSelected("${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}");
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _tableCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setTab(NavTab.home),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: TextButton(
                  onPressed: authProvider.settingsResource is Loading ? null : _updateSettings,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: authProvider.settingsResource is Loading
                      ? SizedBox(
                          width: 18.sp,
                          height: 18.sp,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'common.update'.tr(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, letterSpacing: 0.3),
                        ),
                ),
              );
            },
          ),
          SizedBox(width: 12.w),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('settings.shop_status'.tr(), Icons.storefront_outlined),
                _buildShopStatusSection(settingsProvider),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.operating_timing'.tr(), Icons.schedule_outlined),
                _buildTimingSection(settingsProvider),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.restaurant_mode'.tr(), Icons.restaurant_menu_outlined),
                _buildRestaurantModeSection(),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.gst_billing'.tr(), Icons.receipt_long_outlined),
                _buildGstBillingSection(settingsProvider),
                if (settingsProvider.isGstEnabled) ...[
                  SizedBox(height: 22.h),
                  _buildSectionHeader('settings.gst_business_details'.tr(), Icons.business_outlined),
                  _buildGstBusinessDetailsSection(settingsProvider),
                ],
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.appearance'.tr(), Icons.palette_outlined),
                _buildThemeSection(),
                SizedBox(height: 22.h),
                _buildSectionHeader('language.title'.tr(), Icons.language),
                _buildLanguageSection(),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.alert_settings'.tr(), Icons.notifications_outlined),
                _buildAlertSection(settingsProvider),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.printer_settings'.tr(), Icons.print_outlined),
                _buildPrinterSection(),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.qr_payments'.tr(), Icons.qr_code_2_outlined),
                _buildQrSettingsSection(settingsProvider),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.app_config'.tr(), Icons.tune_outlined),
                _buildKdsConfigSection(settingsProvider),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.feedback_section'.tr(), Icons.feedback_outlined),
                _buildFeedbackSection(),
                SizedBox(height: 22.h),
                _buildSectionHeader('settings.about'.tr(), Icons.info_outline),
                _buildAboutSection(),
                SizedBox(height: 28.h),
                _buildLogoutButton(),
                SizedBox(height: 28.h),
                _buildUpcomingFeatures(),
                SizedBox(height: 40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, [IconData? icon]) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 15.h,
            decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(2.r)),
          ),
          SizedBox(width: 8.w),
          if (icon != null) ...[Icon(icon, size: 16.sp, color: AppColors.grey), SizedBox(width: 6.w)],
          Text(
            title,
            style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      boxShadow: AppColors.subtleShadow,
    );
  }

  Widget _buildGstBillingSection(SettingsProvider settings) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(
          Icons.receipt_long_outlined,
          color: settings.isGstEnabled ? AppColors.primaryBlue : AppColors.grey,
          size: 22.sp,
        ),
        title: Text('settings.enable_gst'.tr(), style: _tileTextStyle()),
        subtitle: Text(
          settings.isGstEnabled
              ? 'settings.gst_active_desc'.tr()
              : 'settings.gst_inactive_desc'.tr(),
          style: TextStyle(fontSize: 11.sp),
        ),
        trailing: _buildCustomSwitch(
          value: settings.isGstEnabled,
          onChanged: (v) => settings.setGstEnabled(v),
        ),
      ),
    );
  }

  Widget _buildGstBusinessDetailsSection(SettingsProvider settings) {
    return Container(
      decoration: _cardDecoration(context),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'settings.gst_tax_info'.tr(),
            style: TextStyle(fontSize: 11.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: settings.gstin,
                selection: TextSelection.collapsed(offset: settings.gstin.length),
              ),
            ),
            onChanged: (v) => settings.setGstin(v),
            style: TextStyle(fontSize: 13.sp),
            decoration: InputDecoration(
              labelText: 'settings.gstin'.tr(),
              hintText: 'settings.gstin_hint'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: settings.legalBusinessName,
                selection: TextSelection.collapsed(offset: settings.legalBusinessName.length),
              ),
            ),
            onChanged: (v) => settings.setLegalBusinessName(v),
            style: TextStyle(fontSize: 13.sp),
            decoration: InputDecoration(
              labelText: 'settings.legal_name'.tr(),
              hintText: 'settings.legal_name_hint'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: settings.businessAddress,
                selection: TextSelection.collapsed(offset: settings.businessAddress.length),
              ),
            ),
            onChanged: (v) => settings.setBusinessAddress(v),
            maxLines: 2,
            style: TextStyle(fontSize: 13.sp),
            decoration: InputDecoration(
              labelText: 'settings.business_address'.tr(),
              hintText: 'settings.business_address_hint'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: settings.state,
                      selection: TextSelection.collapsed(offset: settings.state.length),
                    ),
                  ),
                  onChanged: (v) => settings.setStateName(v),
                  style: TextStyle(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'settings.state'.tr(),
                    hintText: 'settings.state_hint'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextField(
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: settings.stateCode,
                      selection: TextSelection.collapsed(offset: settings.stateCode.length),
                    ),
                  ),
                  onChanged: (v) => settings.setStateCode(v),
                  style: TextStyle(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'settings.state_code'.tr(),
                    hintText: 'settings.state_code_hint'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopStatusSection(SettingsProvider settings) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.storefront, color: settings.isShopOpen ? AppColors.primaryBlue : AppColors.grey, size: 22.sp),
            title: Text('settings.shop_onoff'.tr(), style: _tileTextStyle()),
            subtitle: Text(
              settings.isShopOpen ? 'settings.shop_accepting'.tr() : 'settings.shop_closed'.tr(),
              style: TextStyle(fontSize: 11.sp),
            ),
            trailing: _buildCustomSwitch(value: settings.isShopOpen, onChanged: (v) => settings.setShopOpen(v)),
          ),
          Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ListTile(
            leading: Icon(
              Icons.category_outlined,
              color: settings.isCategoryDisplayOn ? AppColors.primaryBlue : AppColors.grey,
              size: 22.sp,
            ),
            title: Text('settings.category_display'.tr(), style: _tileTextStyle()),
            subtitle: Text('settings.category_display_desc'.tr(), style: TextStyle(fontSize: 11.sp)),
            trailing: _buildCustomSwitch(value: settings.isCategoryDisplayOn, onChanged: (v) => settings.setCategoryDisplay(v)),
          ),
          Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ListTile(
            leading: Icon(
              Icons.point_of_sale_outlined,
              color: settings.isGoPosEnabled ? AppColors.primaryBlue : AppColors.grey,
              size: 22.sp,
            ),
            title: Text('settings.go_pos_button'.tr(), style: _tileTextStyle()),
            subtitle: Text('settings.go_pos_desc'.tr(), style: TextStyle(fontSize: 11.sp)),
            trailing: _buildCustomSwitch(
              value: settings.isGoPosEnabled,
              onChanged: (v) {
                settings.setGoPosEnabled(v);
                Provider.of<AuthProvider>(context, listen: false).setGoPosEnabled(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantModeSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final String currentMode = authProvider.restaurantMode;
    final int currentTableCount = authProvider.tableCount;

    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('settings.operation_mode'.tr(), style: _tileTextStyle()),
                        Text(
                          'settings.operation_mode_desc'.tr(),
                          style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'takeaway',
                        label: Text('common.takeaway'.tr()),
                        icon: Icon(Icons.shopping_bag_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: 'dine_in',
                        label: Text('common.dine_in'.tr()),
                        icon: Icon(Icons.table_restaurant_outlined, size: 18),
                      ),
                      ButtonSegment(value: 'both', label: Text('common.both'.tr()), icon: Icon(Icons.grid_view_rounded, size: 18)),
                    ],
                    selected: {currentMode},
                    onSelectionChanged: (newSelection) {
                      authProvider.setRestaurantMode(newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      selectedBackgroundColor: AppColors.primaryBlue,
                      selectedForegroundColor: Colors.white,
                      side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                      textStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (currentMode != 'common.takeaway'.tr()) ...[
            Divider(height: 1, indent: 16.w, endIndent: 16.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ListTile(
              leading: Icon(Icons.table_bar, color: AppColors.primaryBlue, size: 22.sp),
              title: Text('settings.number_of_tables'.tr(), style: _tileTextStyle()),
              subtitle: Text('settings.configure_floor'.tr(), style: TextStyle(fontSize: 11.sp)),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: currentTableCount > 1
                          ? () {
                              final newVal = currentTableCount - 1;
                              authProvider.setTableCount(newVal);
                              _tableCountController.text = newVal.toString();
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 45.w,
                      child: TextField(
                        controller: _tableCountController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          if (val.isEmpty) return;
                          final count = int.tryParse(val);
                          if (count != null && count > 0) {
                            authProvider.setTableCount(count);
                          } else {
                            _tableCountController.text = '1';
                            authProvider.setTableCount(1);
                          }
                        },
                        onSubmitted: (val) {
                          if (val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0) {
                            _tableCountController.text = '1';
                            authProvider.setTableCount(1);
                          }
                        },
                        onTapOutside: (event) {
                          if (_tableCountController.text.isEmpty ||
                              int.tryParse(_tableCountController.text) == null ||
                              int.parse(_tableCountController.text) <= 0) {
                            _tableCountController.text = '1';
                            authProvider.setTableCount(1);
                          }
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: () {
                        final newVal = currentTableCount + 1;
                        authProvider.setTableCount(newVal);
                        _tableCountController.text = newVal.toString();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Column(
            children: [
              _buildThemeOption(
                icon: Icons.light_mode_outlined,
                title: 'settings.light_mode'.tr(),
                isSelected: themeProvider.themeMode == ThemeMode.light,
                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
              ),
              Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              _buildThemeOption(
                icon: Icons.dark_mode_outlined,
                title: 'settings.dark_mode'.tr(),
                isSelected: themeProvider.themeMode == ThemeMode.dark,
                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
              ),
              Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              _buildThemeOption(
                icon: Icons.brightness_auto_outlined,
                title: 'settings.system_default'.tr(),
                isSelected: themeProvider.themeMode == ThemeMode.system,
                onTap: () => themeProvider.setThemeMode(ThemeMode.system),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageSection() {
    final code = context.locale.languageCode;
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(Icons.language, color: AppColors.primaryBlue, size: 22.sp),
        title: Text('language.title'.tr(), style: _tileTextStyle()),
        subtitle: Text('language.subtitle'.tr(), style: TextStyle(fontSize: 11.sp)),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleService.nativeLabel(code),
                style: TextStyle(fontSize: 12.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.chevron_right, size: 16.sp, color: AppColors.primaryBlue),
            ],
          ),
        ),
        onTap: () => showLanguageSelector(context),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryBlue : AppColors.grey, size: 22.sp),
      title: Text(title, style: _tileTextStyle()),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20.sp)
          : Icon(Icons.circle_outlined, color: AppColors.grey.withValues(alpha: 0.3), size: 20.sp),
      onTap: onTap,
    );
  }

  Widget _buildAlertSection(SettingsProvider settings) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.notifications_active_outlined, color: AppColors.primaryBlue, size: 22.sp),
            title: Text('settings.push_notifications'.tr(), style: _tileTextStyle()),
            subtitle: Text('settings.push_desc'.tr(), style: TextStyle(fontSize: 11.sp)),
            trailing: _buildCustomSwitch(value: settings.isNotificationOn, onChanged: _onNotificationToggle),
          ),
          Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ListTile(
            leading: Icon(Icons.volume_up_outlined, color: AppColors.primaryBlue, size: 22.sp),
            title: Text('settings.alert_tone'.tr(), style: _tileTextStyle()),
            subtitle: Text('settings.alert_tone_desc'.tr(), style: TextStyle(fontSize: 11.sp)),
            trailing: _buildCustomSwitch(value: settings.isAlertToneOn, onChanged: _onAlertToneToggle),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSettingsSection(SettingsProvider settings) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.qr_code_scanner,
              color: settings.isQrEnabled ? AppColors.primaryBlue : AppColors.grey,
              size: 22.sp,
            ),
            title: Text('settings.print_qr'.tr(), style: _tileTextStyle()),
            subtitle: Text('settings.print_qr_desc'.tr(), style: TextStyle(fontSize: 11.sp)),
            trailing: _buildCustomSwitch(value: settings.isQrEnabled, onChanged: (v) => settings.setQrEnabled(v)),
          ),
          if (settings.isQrEnabled) ...[
            Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 34.w),
                      Text(
                        'settings.upi_id_label'.tr(),
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      SizedBox(width: 34.w),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => settings.setUpiId(v),
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                              text: settings.upiId,
                              selection: TextSelection.collapsed(offset: settings.upiId.length),
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                          decoration: InputDecoration(
                            hintText: 'settings.upi_id_hint'.tr(),
                            hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                            isDense: true,
                            filled: true,
                            fillColor: Theme.of(context).scaffoldBackgroundColor,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrinterSection() {
    final printerService = PrinterService();
    return Column(
      children: [
        Container(
          decoration: _cardDecoration(context),
          clipBehavior: Clip.antiAlias,
          child: _buildDetailTile(
            Icons.bluetooth_audio,
            'settings.bluetooth_printer'.tr(),
            printerService.isEthernet ? 'settings.inactive'.tr() : (printerService.device?.name ?? 'settings.configure'.tr()),
            isAction: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()));
            },
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: _cardDecoration(context),
          clipBehavior: Clip.antiAlias,
          child: _buildDetailTile(
            Icons.lan_outlined,
            'settings.ethernet_printer'.tr(),
            !printerService.isEthernet ? 'settings.inactive'.tr() : (printerService.ipAddress ?? 'settings.configure'.tr()),
            isAction: true,
            onTap: _showEthernetConfigDialog,
          ),
        ),
        if (!printerService.isEthernet && printerService.device != null) ...[
          SizedBox(height: 10.h),
          Container(
            decoration: _cardDecoration(context),
            clipBehavior: Clip.antiAlias,
            child: _buildDetailTile(
              Icons.straighten,
              'settings.paper_size'.tr(),
              printerService.paperSizeIndex == 1 ? '80mm' : '58mm',
              isAction: true,
              onTap: () => _showPaperSizeSelection(context),
            ),
          ),
        ],
        SizedBox(height: 10.h),
        Container(
          decoration: _cardDecoration(context),
          clipBehavior: Clip.antiAlias,
          child: _buildDetailTile(
            Icons.soup_kitchen_outlined,
            'settings.kitchen_print_items'.tr(),
            'settings.manage'.tr(),
            isAction: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const KitchenPrintItemsScreen()));
            },
          ),
        ),
      ],
    );
  }

  void _showPaperSizeSelection(BuildContext context) {
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
    int tempSizeIndex = printerProvider.paperSizeIndex;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text('settings.printer_paper_size'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _paperSizeItem(context, 0, '58mm (2-inch)', tempSizeIndex, (val) => setDialogState(() => tempSizeIndex = val)),
                SizedBox(height: 10.h),
                _paperSizeItem(context, 1, '80mm (3-inch)', tempSizeIndex, (val) => setDialogState(() => tempSizeIndex = val)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.grey)),
              ),
              TextButton(
                onPressed: () {
                  printerProvider.setPaperSize(tempSizeIndex);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text('common.done'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paperSizeItem(BuildContext context, int index, String label, int currentIndex, ValueChanged<int> onChanged) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onChanged(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20.sp),
          ],
        ),
      ),
    );
  }

  void _showEthernetConfigDialog() {
    final printerService = PrinterService();
    final controller = TextEditingController(text: printerService.ipAddress);
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text('settings.ethernet_config'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('settings.enter_ip'.tr(), style: TextStyle(fontSize: 12)),
              SizedBox(height: 12.h),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'settings.ip_hint'.tr(),
                  prefixIcon: Icon(Icons.lan_outlined, color: AppColors.primaryBlue, size: 20.sp),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr(), style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isTesting
                  ? null
                  : () async {
                      if (controller.text.isEmpty) return;
                      setDialogState(() => isTesting = true);

                      final success = await printerService.connectEthernet(controller.text);

                      if (mounted) {
                        setDialogState(() => isTesting = false);
                        if (success) {
                          if (context.mounted) Navigator.pop(context);
                          Provider.of<SettingsProvider>(context, listen: false).refresh();
                          CustomSnackbar.show(context, message: 'settings.ethernet_connected'.tr(), isError: false);
                        } else {
                          CustomSnackbar.show(context, message: 'settings.conn_failed_ip'.tr());
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(0, 44),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: isTesting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('settings.connect_save'.tr(), style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKdsConfigSection(SettingsProvider settings) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(Icons.soup_kitchen_outlined, color: AppColors.primaryBlue, size: 22.sp),
        title: Text('settings.kds_label'.tr(), style: _tileTextStyle()),
        subtitle: Text('settings.kds_desc'.tr(), style: TextStyle(fontSize: 11.sp)),
        trailing: _buildCustomSwitch(value: settings.isKdsEnabled, onChanged: (v) => settings.setKdsEnabled(v)),
      ),
    );
  }

  Widget _buildCustomSwitch({required bool value, required ValueChanged<bool> onChanged}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: (value ? Colors.green : Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              value ? "ACTIVE" : "OFF",
              style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold, color: value ? Colors.green : Colors.red),
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 24.h,
            width: 40.w,
            child: Transform.scale(
              scale: 0.7,
              child: CupertinoSwitch(value: value, activeTrackColor: AppColors.primaryBlue, onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      decoration: _cardDecoration(context),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          children: [
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: 'settings.feedback_hint'.tr(),
                hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                ),
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                filled: true,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_feedbackController.text.trim().isNotEmpty) {
                    _feedbackController.clear();
                    CustomSnackbar.show(context, message: 'settings.feedback_thanks'.tr(), isError: false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                ),
                child: Text(
                  'settings.submit_feedback'.tr(),
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingSection(SettingsProvider settings) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildDetailTile(
            Icons.wb_sunny_outlined,
            'settings.morning_slot'.tr(),
            '${settings.morningStart} - ${settings.morningEnd}',
            isAction: true,
            onTap: () => _selectSlotTime('settings.morning'.tr(), settings),
          ),
          Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          _buildDetailTile(
            Icons.light_mode_outlined,
            'settings.afternoon_slot'.tr(),
            '${settings.afternoonStart} - ${settings.afternoonEnd}',
            isAction: true,
            onTap: () => _selectSlotTime('settings.afternoon'.tr(), settings),
          ),
          Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          _buildDetailTile(
            Icons.wb_twilight,
            'settings.evening_slot'.tr(),
            '${settings.eveningStart} - ${settings.eveningEnd}',
            isAction: true,
            onTap: () => _selectSlotTime('settings.evening'.tr(), settings),
          ),
        ],
      ),
    );
  }

  void _selectSlotTime(String slot, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text('settings.select_slot'.tr(namedArgs: {'slot': slot})),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('settings.start_time'.tr()),
                  trailing: Text(
                    slot == 'settings.morning'.tr()
                        ? settings.morningStart
                        : slot == 'settings.afternoon'.tr()
                        ? settings.afternoonStart
                        : settings.eveningStart,
                    style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    if (slot == 'settings.morning'.tr()) {
                      await _selectTime(dialogContext, settings.morningStart, (v) {
                        settings.updateMorningSlot(v, settings.morningEnd);
                      });
                    }
                    if (slot == 'settings.afternoon'.tr()) {
                      await _selectTime(dialogContext, settings.afternoonStart, (v) {
                        settings.updateAfternoonSlot(v, settings.afternoonEnd);
                      });
                    }
                    if (slot == 'settings.evening'.tr()) {
                      await _selectTime(dialogContext, settings.eveningStart, (v) {
                        settings.updateEveningSlot(v, settings.eveningEnd);
                      });
                    }
                    setDialogState(() {});
                  },
                ),
                ListTile(
                  title: Text('settings.end_time'.tr()),
                  trailing: Text(
                    slot == 'settings.morning'.tr()
                        ? settings.morningEnd
                        : slot == 'settings.afternoon'.tr()
                        ? settings.afternoonEnd
                        : settings.eveningEnd,
                    style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    if (slot == 'settings.morning'.tr()) {
                      await _selectTime(dialogContext, settings.morningEnd, (v) {
                        settings.updateMorningSlot(settings.morningStart, v);
                      });
                    }
                    if (slot == 'settings.afternoon'.tr()) {
                      await _selectTime(dialogContext, settings.afternoonEnd, (v) {
                        settings.updateAfternoonSlot(settings.afternoonStart, v);
                      });
                    }
                    if (slot == 'settings.evening'.tr()) {
                      await _selectTime(dialogContext, settings.eveningEnd, (v) {
                        settings.updateEveningSlot(settings.eveningStart, v);
                      });
                    }
                    setDialogState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('common.done'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildDetailTile(
            Icons.support_agent_outlined,
            'support.title'.tr(),
            'settings.contact_us'.tr(),
            isAction: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
            },
          ),
          Divider(height: 1, indent: 50.w, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          _buildDetailTile(Icons.info_outline, 'settings.version'.tr(), '1.0.2'),
        ],
      ),
    );
  }

  Widget _buildUpcomingFeatures() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'settings.upcoming'.tr(),
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.amber.shade800, letterSpacing: 0.8),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildFeatureItem(Icons.payments_outlined, 'settings.upcoming_payment'.tr()),
          _buildFeatureItem(Icons.card_giftcard_outlined, 'settings.upcoming_loyalty'.tr()),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: Colors.amber.shade700.withValues(alpha: 0.8)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value, {bool isAction = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue, size: 22.sp),
      title: Text(title, style: _tileTextStyle()),
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: isAction ? AppColors.primaryBlue : AppColors.grey,
                fontWeight: isAction ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isAction) ...[SizedBox(width: 4.w), Icon(Icons.chevron_right, size: 16.sp, color: AppColors.primaryBlue)],
          ],
        ),
      ),
      onTap: onTap,
    );
  }

  TextStyle _tileTextStyle() {
    return TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600);
  }

  Widget _buildLogoutButton() {
    return Center(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return OutlinedButton.icon(
            onPressed: () => _showLogoutConfirmation(context, authProvider),
            icon: Icon(Icons.logout, color: AppColors.errorRed, size: 18.sp),
            label: Text(
              'settings.logout_portal'.tr(),
              style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 13.sp, letterSpacing: 0.5),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.4)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.confirm_logout'.tr()),
        content: Text('settings.logout_confirm_msg'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _performLogout(authProvider);
            },
            child: Text(
              'settings.logout'.tr(),
              style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _performLogout(AuthProvider authProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final success = await authProvider.logout();
    if (mounted) {
      Navigator.pop(context);
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      } else {
        CustomSnackbar.show(context, message: authProvider.logoutResource.failure?.message ?? 'settings.logout_failed'.tr());
      }
    }
  }
}
