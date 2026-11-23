import '../../models/shop_settings_model.dart';
import '../../core/utils/resource.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Resource<UserEntity>> login(
    String email,
    String password, {
    String? deviceId,
    String? deviceType,
    String? fcmToken,
  });
  Future<Resource<void>> logout({String? deviceId});
  Future<Resource<ShopSettingsModel>> getShopSettings();
  Future<Resource<ShopSettingsModel>> updateShopSettings(ShopSettingsModel settings);
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
  Future<void> saveGoPosEnabled(bool status);
  bool getGoPosEnabled();
  Future<void> saveQrEnabled(bool status);
  bool getQrEnabled();
  Future<void> saveUpiId(String upiId);
  String getUpiId();
}
