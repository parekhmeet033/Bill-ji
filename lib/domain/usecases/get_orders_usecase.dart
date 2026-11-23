import '../../core/utils/resource.dart';
import '../../models/order_model.dart';
import '../repositories/order_repository.dart';

class GetOrdersUseCase {
  final OrderRepository repository;

  GetOrdersUseCase(this.repository);

  Future<Resource<List<OrderModel>>> execute() {
    return repository.getOrders();
  }
}
