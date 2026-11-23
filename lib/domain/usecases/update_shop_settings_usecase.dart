import '../../core/utils/resource.dart';
import '../../models/shop_settings_model.dart';
import '../repositories/auth_repository.dart';

class UpdateShopSettingsUseCase {
  final AuthRepository repository;

  UpdateShopSettingsUseCase(this.repository);

  Future<Resource<ShopSettingsModel>> execute(ShopSettingsModel settings) {
    return repository.updateShopSettings(settings);
  }
}
