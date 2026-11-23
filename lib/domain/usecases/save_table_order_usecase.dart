import '../../core/utils/resource.dart';
import '../repositories/order_repository.dart';

class SaveTableOrderUseCase {
  final OrderRepository repository;

  SaveTableOrderUseCase(this.repository);

  Future<Resource<void>> call(Map<String, dynamic> data) async {
    return await repository.saveTableOrder(data);
  }
}
