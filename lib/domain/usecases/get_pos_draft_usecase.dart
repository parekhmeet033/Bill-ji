import '../../core/utils/resource.dart';
import '../../models/order_model.dart';
import '../repositories/order_repository.dart';

/// Fetches the user's in-progress take-away draft (the auto-saved POS cart) so
/// the POS screen can restore it after an app/device restart. Returns null when
/// there is no draft.
class GetPosDraftUseCase {
  final OrderRepository repository;

  GetPosDraftUseCase(this.repository);

  Future<Resource<OrderModel?>> call() async {
    return await repository.getPosDraft();
  }
}
