import '../../core/utils/resource.dart';
import '../repositories/order_repository.dart';

/// Discards the user's in-progress take-away draft (the auto-saved POS cart),
/// used when the POS order is cancelled so it isn't restored later.
class ClearPosDraftUseCase {
  final OrderRepository repository;

  ClearPosDraftUseCase(this.repository);

  Future<Resource<void>> call() async {
    return await repository.clearPosDraft();
  }
}
