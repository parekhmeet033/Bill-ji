import '../../core/utils/resource.dart';
import '../../models/order_model.dart';
import '../../models/pagination_model.dart';
import '../repositories/order_repository.dart';

class GetOrdersListUseCase {
  final OrderRepository repository;

  GetOrdersListUseCase(this.repository);

  Future<Resource<PaginatedData<List<OrderModel>>>> execute({
    required String status,
    required String orderType,
    required String search,
    required String startDate,
    required String endDate,
    required int page,
  }) {
    return repository.getOrdersList(
      status: status,
      orderType: orderType,
      search: search,
      startDate: startDate,
      endDate: endDate,
      page: page,
    );
  }
}
