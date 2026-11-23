import '../../core/utils/resource.dart';
import '../../models/category_model.dart';
import '../repositories/menu_repository.dart';

class GetCategoryUseCase {
  final MenuRepository repository;

  GetCategoryUseCase(this.repository);

  Future<Resource<List<CategoryModel>>> execute() {
    return repository.getCategoryList();
  }
}
