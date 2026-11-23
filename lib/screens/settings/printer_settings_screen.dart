import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:lineless/core/services/printer_service.dart';
import 'package:lineless/core/theme/app_colors.dart';
import 'package:lineless/core/utils/custom_snackbar.dart';
import 'package:lineless/providers/printer_provider.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PrinterProvider>(context, listen: false);
      provider.init();
    });
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(
          'printer.bt_off'.tr(),
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'printer.enable_bt_hint'.tr(),
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('common.ok'.tr()))],
      ),
    );
  }

  Future<void> _connectToDevice(PrinterProvider provider, BluetoothInfo device) async {
    final success = await provider.connectToDevice(device);
    if (mounted) {
      if (success) {
        CustomSnackbar.show(context, message: 'printer.connected_to'.tr(namedArgs: {'name': device.name}), isError: false);
        _showPaperSizeDialog(provider);
      } else {
        CustomSnackbar.show(context, message: 'printer.conn_failed'.tr());
      }
    }
  }

  void _showPaperSizeDialog(PrinterProvider provider) {
    int tempSizeIndex = provider.paperSizeIndex;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text('printer.select_paper'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'printer.paper_width_hint'.tr(),
                  style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
                ),
                SizedBox(height: 20.h),
                _paperSizeOption(
                  title: '58mm (2-inch)',
                  subtitle: 'printer.portable'.tr(),
                  index: 0,
                  currentIndex: tempSizeIndex,
                  onChanged: (val) => setDialogState(() => tempSizeIndex = val),
                ),
                SizedBox(height: 12.h),
                _paperSizeOption(
                  title: '80mm (3-inch)',
                  subtitle: 'printer.desktop'.tr(),
                  index: 1,
                  currentIndex: tempSizeIndex,
                  onChanged: (val) => setDialogState(() => tempSizeIndex = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  await provider.setPaperSize(tempSizeIndex);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('common.done'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paperSizeOption({
    required String title,
    required String subtitle,
    required int index,
    required int currentIndex,
    required ValueChanged<int> onChanged,
  }) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onChanged(index),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.lightGrey),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: currentIndex,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              activeColor: AppColors.primaryBlue,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(fontSize: 11.sp, color: AppColors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final printerProvider = context.watch<PrinterProvider>();

    // Check if bluetooth was turned off during session
    if (!printerProvider.isBluetoothOn && !printerProvider.isLoading) {
      // We can't show dialog directly in build.
      // This logic should ideally be in the provider's loadDevices and trigger a UI signal.
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text('printer.title'.tr()),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            tooltip: 'common.refresh'.tr(),
            onPressed: printerProvider.isLoading ? null : () => printerProvider.loadDevices(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (printerProvider.selectedDevice != null && printerProvider.isBluetoothOn) 
            _buildConnectedPrinterCard(printerProvider.selectedDevice!),
          _buildPairedDevicesHeader(printerProvider),
          Expanded(child: _buildDeviceList(printerProvider)),
          _buildBottomHint(),
        ],
      ),
    );
  }

  Widget _buildConnectedPrinterCard(BluetoothInfo device) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 0),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.print_rounded, color: AppColors.primaryBlue, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'printer.selected_printer'.tr(),
                  style: TextStyle(fontSize: 11.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(
                  device.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  device.macAdress,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20.r)),
            child: Text(
              'printer.active'.tr(),
              style: TextStyle(fontSize: 10.sp, color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairedDevicesHeader(PrinterProvider provider) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 16.w, 8.h),
      child: Text(
        provider.isBluetoothOn ? 'printer.paired_devices'.tr() : 'printer.bt_off_caps'.tr(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: provider.isBluetoothOn 
              ? Theme.of(context).textTheme.bodySmall?.color 
              : Colors.redAccent,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDeviceList(PrinterProvider provider) {
    final theme = Theme.of(context);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.devices.isEmpty) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 16.h),
            Icon(Icons.bluetooth_searching_rounded, size: 52.sp, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
            SizedBox(height: 16.h),
            Text(
              'printer.no_paired'.tr(),
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16.sp, color: AppColors.primaryBlue),
                      SizedBox(width: 8.w),
                      Text(
                        'printer.how_to_pair'.tr(),
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildStep('1', 'Turn on your Thermal printer'),
                  _buildStep('2', 'Open your phone\'s Settings → Connected devices → Pair new device'),
                  _buildStep('3', 'Select "Thermal printer" from the list and enter PIN 0000'),
                  _buildStep('4', 'Come back here and tap the refresh button ↻'),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            if (!provider.isPermissionGranted)
              OutlinedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                  provider.loadDevices();
                },
                icon: Icon(Icons.security_rounded, size: 16.sp),
                label: Text('printer.grant_perms'.tr(), style: TextStyle(fontSize: 13.sp)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: BorderSide(color: AppColors.primaryBlue),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              )
            else if (!provider.isBluetoothOn)
              Text(
                'printer.turn_on_bt'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: provider.devices.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final device = provider.devices[index];
        final isSelected = provider.selectedDevice?.macAdress == device.macAdress;
        return _buildDeviceTile(provider, device, isSelected);
      },
    );
  }

  Widget _buildDeviceTile(PrinterProvider provider, BluetoothInfo device, bool isSelected) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.06) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : theme.dividerColor.withValues(alpha: 0.1),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: (isSelected ? AppColors.primaryBlue : theme.textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.print_outlined,
            color: isSelected ? AppColors.primaryBlue : theme.textTheme.bodySmall?.color,
            size: 20.sp,
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
        ),
        subtitle: Text(
          device.macAdress,
          style: TextStyle(fontSize: 11.sp, color: theme.textTheme.bodySmall?.color),
        ),
        trailing: provider.connectingAddress == device.macAdress
            ? SizedBox(width: 20.sp, height: 20.sp, child: const CircularProgressIndicator(strokeWidth: 2))
            : isSelected
            ? Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 22.sp)
            : Icon(
                Icons.radio_button_unchecked_rounded,
                color: (theme.textTheme.bodySmall?.color ?? AppColors.grey).withValues(alpha: 0.5),
                size: 22.sp,
              ),
        onTap: (provider.isConnecting || isSelected) ? null : () => _connectToDevice(provider, device),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20.sp,
            height: 20.sp,
            decoration: BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
            child: Center(
              child: Text(
                number,
                style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp, color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHint() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14.sp, color: Theme.of(context).textTheme.bodySmall?.color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'printer.tap_device_hint'.tr(),
              style: TextStyle(fontSize: 11.sp, color: Theme.of(context).textTheme.bodySmall?.color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
