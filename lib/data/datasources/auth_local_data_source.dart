import 'package:hive/hive.dart';
import '../../core/constants/api_constants.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  String? getToken();
  Future<void> saveUserId(String id);
  String? getUserId();
  Future<void> saveDeviceId(String id);
  String? getDeviceId();
  Future<void> saveEventUserId(String id);
  String? getEventUserId();
  Future<void> saveAlertToneStatus(bool status);
  bool getAlertToneStatus();
  Future<void> saveRestaurantMode(String mode);
  String getRestaurantMode();
  Future<void> saveTableCount(int count);
  int getTableCount();
  Future<void> saveNotificationStatus(bool status);
  bool getNotificationStatus();
  Future<void> saveKdsEnabled(bool status);
  bool getKdsEnabled();
  Future<void> saveQrEnabled(bool status);
  bool getQrEnabled();
  Future<void> saveGoPosEnabled(bool status);
  bool getGoPosEnabled();
  Future<void> saveUpiId(String upiId);
  String getUpiId();
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box tokenBox;

  AuthLocalDataSourceImpl(this.tokenBox);

  @override
  Future<void> saveToken(String token) async {
    await tokenBox.put(CacheConstants.authToken, token);
  }

  @override
  String? getToken() {
    return tokenBox.get(CacheConstants.authToken);
  }

  @override
  Future<void> saveUserId(String id) async {
    await tokenBox.put(CacheConstants.userId, id);
  }

  @override
  String? getUserId() {
    return tokenBox.get(CacheConstants.userId);
  }

  @override
  Future<void> saveDeviceId(String id) async {
    await tokenBox.put('deviceId', id);
  }

  @override
  String? getDeviceId() {
    return tokenBox.get('deviceId');
  }

  @override
  Future<void> saveEventUserId(String id) async {
    await tokenBox.put('eventUserId', id);
  }

  @override
  String? getEventUserId() {
    return tokenBox.get('eventUserId');
  }

  @override
  Future<void> saveAlertToneStatus(bool status) async {
    await tokenBox.put('alertToneOn', status);
  }

  @override
  bool getAlertToneStatus() {
    return tokenBox.get('alertToneOn', defaultValue: true);
  }

  @override
  Future<void> saveRestaurantMode(String mode) async {
    await tokenBox.put('restaurantMode', mode);
  }

  @override
  String getRestaurantMode() {
    return tokenBox.get('restaurantMode', defaultValue: 'Both');
  }

  @override
  Future<void> saveTableCount(int count) async {
    await tokenBox.put('tableCount', count);
  }

  @override
  int getTableCount() {
    return tokenBox.get('tableCount', defaultValue: 10);
  }

  @override
  Future<void> saveNotificationStatus(bool status) async {
    await tokenBox.put('notificationOn', status);
  }

  @override
  bool getNotificationStatus() {
    return tokenBox.get('notificationOn', defaultValue: true);
  }

  @override
  Future<void> saveKdsEnabled(bool status) async {
    await tokenBox.put('kdsEnabled', status);
  }

  @override
  bool getKdsEnabled() {
    return tokenBox.get('kdsEnabled', defaultValue: true);
  }

  @override
  Future<void> saveQrEnabled(bool status) async {
    await tokenBox.put('qrEnabled', status);
  }

  @override
  bool getQrEnabled() {
    return tokenBox.get('qrEnabled', defaultValue: false);
  }

  @override
  Future<void> saveGoPosEnabled(bool status) async {
    await tokenBox.put('goPosEnabled', status);
  }

  @override
  bool getGoPosEnabled() {
    return tokenBox.get('goPosEnabled', defaultValue: true);
  }

  @override
  Future<void> saveUpiId(String upiId) async {
    await tokenBox.put('upiId', upiId);
  }

  @override
  String getUpiId() {
    return tokenBox.get('upiId', defaultValue: '');
  }

  @override
  Future<void> clear() async {
    await tokenBox.clear();
  }
}
