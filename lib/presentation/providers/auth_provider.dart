import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/services/device_service.dart';
import '../../core/services/printer_service.dart';
import '../../core/utils/resource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_shop_settings_usecase.dart';
import '../../domain/usecases/update_shop_settings_usecase.dart';
import '../../models/shop_settings_model.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetShopSettingsUseCase? getShopSettingsUseCase;
  final UpdateShopSettingsUseCase? updateShopSettingsUseCase;
  final AuthRepository repository;

  AuthProvider(
    this.loginUseCase,
    this.logoutUseCase,
    this.repository, {
    this.getShopSettingsUseCase,
    this.updateShopSettingsUseCase,
  }) {
    // Keep screen on by default for the entire app
    WakelockPlus.enable();
  }

  Resource<UserEntity> _loginResource = Initial();

  Resource<UserEntity> get loginResource => _loginResource;

  Resource<void> _logoutResource = Initial();

  Resource<void> get logoutResource => _logoutResource;

  ShopSettingsModel? _shopSettings;

  ShopSettingsModel? get shopSettings => _shopSettings;

  Resource<ShopSettingsModel> _settingsResource = Initial();

  Resource<ShopSettingsModel> get settingsResource => _settingsResource;

  Future<void> login(String email, String password, {String? deviceId, String? deviceType, String? fcmToken}) async {
    _loginResource = Loading();
    notifyListeners();

    final id = deviceId ?? await DeviceService.getDeviceId();
    final type = deviceType ?? DeviceService.getDeviceType();
    final token = fcmToken ?? await DeviceService.getFcmToken();

    _loginResource = await loginUseCase.execute(email, password, deviceId: id, deviceType: type, fcmToken: token);

    if (_loginResource is Success) {
      // Point the printer at THIS user's QR/UPI so another user's "Print QR
      // in Bill" setting can't carry over to this session's bills.
      syncPrinterSessionSettings();
      if (isNotificationOn) {
        await FirebaseMessaging.instance.subscribeToTopic('orders');
      }
    }

    notifyListeners();
  }

  /// Keeps the printer's copy of the per-session QR/UPI settings aligned with
  /// the logged-in user's local values, so the "Print QR in Bill" option only
  /// takes effect for a user who has enabled it and entered a UPI ID.
  void syncPrinterSessionSettings() {
    PrinterService().setQrSettings(isQrEnabled, upiId);
  }

  Future<bool> logout({String? deviceId}) async {
    _logoutResource = Loading();
    notifyListeners();

    final id = deviceId ?? await DeviceService.getDeviceId();

    final result = await logoutUseCase.execute(deviceId: id);
    _logoutResource = result;

    if (result is Success) {
      // Clear the printer's QR/UPI so the next user who logs in on this device
      // doesn't inherit the previous user's "Print QR in Bill" settings.
      await PrinterService().setQrSettings(false, '');
      await FirebaseMessaging.instance.unsubscribeFromTopic('orders');
    }

    notifyListeners();

    return result is Success;
  }

  Future<void> fetchShopSettings() async {
    if (getShopSettingsUseCase == null) return;

    _settingsResource = Loading();
    notifyListeners();

    final result = await getShopSettingsUseCase!.execute();
    _settingsResource = result;
    if (result is Success) {
      _shopSettings = result.data;
    }
    notifyListeners();
  }

  Future<bool> updateShopSettings(ShopSettingsModel settings) async {
    if (updateShopSettingsUseCase == null) return false;

    _settingsResource = Loading();
    notifyListeners();

    final result = await updateShopSettingsUseCase!.execute(settings);
    _settingsResource = result;
    if (result is Success) {
      _shopSettings = result.data;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  bool get isAlertToneOn => repository.getAlertToneStatus();

  Future<void> setAlertToneStatus(bool status) async {
    await repository.saveAlertToneStatus(status);
    notifyListeners();
  }

  bool get isNotificationOn => repository.getNotificationStatus();

  Future<void> setNotificationStatus(bool status) async {
    await repository.saveNotificationStatus(status);
    if (status) {
      await FirebaseMessaging.instance.subscribeToTopic('orders');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('orders');
    }
    notifyListeners();
  }

  bool get isKdsEnabled => repository.getKdsEnabled();

  Future<void> setKdsEnabled(bool status) async {
    await repository.saveKdsEnabled(status);
    notifyListeners();
  }

  bool get isGoPosEnabled => repository.getGoPosEnabled();

  Future<void> setGoPosEnabled(bool status) async {
    await repository.saveGoPosEnabled(status);
    notifyListeners();
  }

  String get restaurantMode => repository.getRestaurantMode();

  Future<void> setRestaurantMode(String mode) async {
    await repository.saveRestaurantMode(mode);
    notifyListeners();
  }

  int get tableCount => repository.getTableCount();

  Future<void> setTableCount(int count) async {
    await repository.saveTableCount(count);
    notifyListeners();
  }

  void syncSettings(String mode, int tables) {
    repository.saveRestaurantMode(mode);
    repository.saveTableCount(tables);
    notifyListeners();
  }

  bool get isQrEnabled => repository.getQrEnabled();

  Future<void> setQrEnabled(bool status) async {
    await repository.saveQrEnabled(status);
    notifyListeners();
  }

  String get upiId => repository.getUpiId();

  Future<void> setUpiId(String upiId) async {
    await repository.saveUpiId(upiId);
    notifyListeners();
  }
}
