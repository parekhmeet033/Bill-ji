import '../../core/utils/resource.dart';
import '../../models/table_product_list_model.dart';
import '../repositories/menu_repository.dart';

class GetTableProductListUseCase {
  final MenuRepository repository;

  GetTableProductListUseCase(this.repository);

  Future<Resource<List<TableCategoryModel>>> execute() {
    return repository.getTableProductList();
  }
}
