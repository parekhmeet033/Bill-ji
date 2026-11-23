import '../../core/utils/resource.dart';
import '../../models/dashboard_model.dart';
import '../repositories/order_repository.dart';

class GetDashboardUseCase {
  final OrderRepository repository;

  GetDashboardUseCase(this.repository);

  Future<Resource<DashboardData>> execute() {
    return repository.getDashboardData();
  }
}
