import '../../core/utils/resource.dart';
import '../repositories/menu_repository.dart';

class UpdateMenuStatusUseCase {
  final MenuRepository repository;

  UpdateMenuStatusUseCase(this.repository);

  Future<Resource<void>> execute({
    required String productId,
    required int status,
  }) {
    return repository.updateMenuStatus(
      productId: productId,
      status: status,
    );
  }
}
