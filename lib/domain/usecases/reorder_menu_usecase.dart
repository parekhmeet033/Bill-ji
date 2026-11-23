import '../../core/utils/resource.dart';
import '../repositories/menu_repository.dart';

class ReorderMenuUseCase {
  final MenuRepository repository;

  ReorderMenuUseCase(this.repository);

  Future<Resource<void>> execute({required int categoryId, required List<int> productIds}) {
    return repository.reorderMenu(categoryId: categoryId, productIds: productIds);
  }
}
