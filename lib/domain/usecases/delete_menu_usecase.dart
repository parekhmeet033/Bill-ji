import '../../core/utils/resource.dart';
import '../repositories/menu_repository.dart';

class DeleteMenuUseCase {
  final MenuRepository repository;

  DeleteMenuUseCase(this.repository);

  Future<Resource<void>> execute(String productId) {
    return repository.deleteMenuItem(productId);
  }
}
