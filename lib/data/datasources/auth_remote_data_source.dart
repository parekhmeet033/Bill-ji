import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'package:lineless/models/shop_settings_model.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<ApiResponse<UserModel>> login(
    String email,
    String password, {
    String? deviceId,
    String? deviceType,
    String? fcmToken,
  });
  Future<void> logout({String? deviceId});
  Future<ApiResponse<ShopSettingsModel>> getShopSettings();
  Future<ApiResponse<ShopSettingsModel>> updateShopSettings(ShopSettingsModel settings);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<ApiResponse<UserModel>> login(
    String email,
    String password, {
    String? deviceId,
    String? deviceType,
    String? fcmToken,
  }) async {
    final response = await dioClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
        'device_type': deviceType,
        'fcm_token': fcmToken,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<void> logout({String? deviceId}) async {
    await dioClient.post(
      ApiConstants.logout,
      data: {'device_id': deviceId},
    );
  }

  @override
  Future<ApiResponse<ShopSettingsModel>> getShopSettings() async {
    final response = await dioClient.post(
      ApiConstants.settings,
      data: {'type': 'get'},
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => ShopSettingsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<ShopSettingsModel>> updateShopSettings(ShopSettingsModel settings) async {
    final response = await dioClient.post(
      ApiConstants.settings,
      data: {
        'type': '',
        'shop_open': settings.isShopOpen ? '0' : '1',
        'morning_start': settings.morningStart,
        'morning_end': settings.morningEnd,
        'afternoon_start': settings.afternoonStart,
        'afternoon_end': settings.afternoonEnd,
        'evening_start': settings.eveningStart,
        'evening_end': settings.eveningEnd,
        'category_display': settings.categoryDisplay ? '1' : '0',
        'generated_code': settings.generatedCode,
        'opration_mode_status': settings.oprationModeStatus,
        'number_of_tables': settings.numberOfTables,
        'gst_enabled': settings.isGstEnabled ? '1' : '0',
        'gstin': settings.gstin,
        'legal_business_name': settings.legalBusinessName,
        'business_address': settings.businessAddress,
        'state': settings.state,
        'state_code': settings.stateCode,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => ShopSettingsModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
