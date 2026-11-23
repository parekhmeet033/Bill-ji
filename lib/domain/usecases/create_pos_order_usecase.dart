import '../../core/utils/resource.dart';
import '../repositories/order_repository.dart';

class CreatePosOrderUseCase {
  final OrderRepository repository;

  CreatePosOrderUseCase(this.repository);

  Future<Resource<Map<String, dynamic>>> call(Map<String, dynamic> data) async {
    return await repository.createPosOrder(data);
  }
}
