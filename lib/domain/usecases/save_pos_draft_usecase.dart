import '../../core/utils/resource.dart';
import '../repositories/order_repository.dart';

/// Upserts the user's in-progress take-away draft (auto-saved POS cart). Uses a
/// dedicated endpoint so it never creates a placed order; on a backend that
/// doesn't support drafts the call simply fails and is ignored.
class SavePosDraftUseCase {
  final OrderRepository repository;

  SavePosDraftUseCase(this.repository);

  Future<Resource<void>> call(Map<String, dynamic> data) async {
    return await repository.savePosDraft(data);
  }
}
