import '../../core/utils/resource.dart';
import '../repositories/menu_repository.dart';

class ReorderCategoriesUseCase {
  final MenuRepository repository;

  ReorderCategoriesUseCase(this.repository);

  Future<Resource<void>> execute(List<int> ids) {
    return repository.reorderCategories(ids);
  }
}
