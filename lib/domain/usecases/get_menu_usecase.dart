import '../../core/utils/resource.dart';
import '../../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

class GetMenuUseCase {
  final MenuRepository repository;

  GetMenuUseCase(this.repository);

  Future<Resource<List<MenuItemModel>>> execute() {
    return repository.getMenuList();
  }
}
