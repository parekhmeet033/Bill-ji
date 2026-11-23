import '../../core/utils/resource.dart';
import '../../models/pending_table_model.dart';
import '../repositories/order_repository.dart';

class GetPendingTablesUseCase {
  final OrderRepository repository;

  GetPendingTablesUseCase(this.repository);

  Future<Resource<List<PendingTableModel>>> execute() async {
    return await repository.getPendingTables();
  }
}
