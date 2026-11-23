import '../../core/utils/resource.dart';
import '../../models/shop_settings_model.dart';
import '../repositories/auth_repository.dart';

class GetShopSettingsUseCase {
  final AuthRepository repository;

  GetShopSettingsUseCase(this.repository);

  Future<Resource<ShopSettingsModel>> execute() {
    return repository.getShopSettings();
  }
}
