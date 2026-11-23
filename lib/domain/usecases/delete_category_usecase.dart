import '../../core/utils/resource.dart';
import '../repositories/menu_repository.dart';

class DeleteCategoryUseCase {
  final MenuRepository repository;

  DeleteCategoryUseCase(this.repository);

  Future<Resource<void>> execute(int id) {
    return repository.deleteCategory(id);
  }
}
