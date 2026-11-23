import '../../core/error/error_handler.dart';
import '../../core/network/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/resource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/shop_settings_model.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Resource<UserEntity>> login(
    String email,
    String password, {
    String? deviceId,
    String? deviceType,
    String? fcmToken,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.login(
          email,
          password,
          deviceId: deviceId,
          deviceType: deviceType,
          fcmToken: fcmToken,
        );
        
        if (response.status && response.token != null) {
          await localDataSource.saveToken(response.token!);
          await localDataSource.saveUserId(response.data!.id.toString());
          if (deviceId != null) {
            await localDataSource.saveDeviceId(deviceId);
          }
          return Success(response.data!);
        } else {
          return Error(ServerFailure(response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> logout({String? deviceId}) async {
    final storedDeviceId = deviceId ?? localDataSource.getDeviceId();
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logout(deviceId: storedDeviceId);
        await localDataSource.clear();
        return Success(null);
      } catch (e) {
        // Even if API fails, we should clear local data for safety
        await localDataSource.clear();
        return Error(ErrorHandler.handle(e));
      }
    } else {
      // Local clear if offline logout attempted
      await localDataSource.clear();
      return Error(NetworkFailure('No internet connection. Local session cleared.'));
    }
  }

  @override
  Future<Resource<ShopSettingsModel>> getShopSettings() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getShopSettings();
        if (response.status && response.data != null) {
          return Success(response.data!);
        } else {
          return Error(ServerFailure(response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<ShopSettingsModel>> updateShopSettings(ShopSettingsModel settings) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateShopSettings(settings);
        if (response.status && response.data != null) {
          return Success(response.data!);
        } else {
          return Error(ServerFailure(response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<void> saveAlertToneStatus(bool status) async {
    await localDataSource.saveAlertToneStatus(status);
  }

  @override
  bool getAlertToneStatus() {
    return localDataSource.getAlertToneStatus();
  }

  @override
  Future<void> saveRestaurantMode(String mode) async {
    await localDataSource.saveRestaurantMode(mode);
  }

  @override
  String getRestaurantMode() {
    return localDataSource.getRestaurantMode();
  }

  @override
  Future<void> saveTableCount(int count) async {
    await localDataSource.saveTableCount(count);
  }

  @override
  int getTableCount() {
    return localDataSource.getTableCount();
  }

  @override
  Future<void> saveNotificationStatus(bool status) async {
    await localDataSource.saveNotificationStatus(status);
  }

  @override
  bool getNotificationStatus() {
    return localDataSource.getNotificationStatus();
  }

  @override
  Future<void> saveKdsEnabled(bool status) async {
    await localDataSource.saveKdsEnabled(status);
  }

  @override
  bool getKdsEnabled() {
    return localDataSource.getKdsEnabled();
  }

  @override
  Future<void> saveGoPosEnabled(bool status) async {
    await localDataSource.saveGoPosEnabled(status);
  }

  @override
  bool getGoPosEnabled() {
    return localDataSource.getGoPosEnabled();
  }

  @override
  Future<void> saveQrEnabled(bool status) async {
    await localDataSource.saveQrEnabled(status);
  }

  @override
  bool getQrEnabled() {
    return localDataSource.getQrEnabled();
  }

  @override
  Future<void> saveUpiId(String upiId) async {
    await localDataSource.saveUpiId(upiId);
  }

  @override
  String getUpiId() {
    return localDataSource.getUpiId();
  }
}
