import '../../core/utils/resource.dart';
import '../repositories/order_repository.dart';

class DeleteOrdersUseCase {
  final OrderRepository repository;

  DeleteOrdersUseCase(this.repository);

  Future<Resource<void>> execute({required String startDate, required String endDate}) async {
    return await repository.deleteOrders(startDate: startDate, endDate: endDate);
  }
}
