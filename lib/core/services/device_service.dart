import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'notification_service.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _androidIdPlugin = AndroidId();

  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final String? androidId = await _androidIdPlugin.getId();
        if (androidId != null) return androidId;
        
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; 
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_id';
      }
    } catch (e) {
      return 'error_device_id';
    }
    return 'unknown_platform_id';
  }

  static String getDeviceType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static Future<String> getFcmToken() async {
    try {
      return await NotificationService().getToken() ?? 'no_token';
    } catch (e) {
      return 'fcm_error';
    }
  }
}
