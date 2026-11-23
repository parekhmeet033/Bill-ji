import '../../core/utils/resource.dart';
import '../repositories/order_repository.dart';

class UpdateOrderStatusUseCase {
  final OrderRepository repository;

  UpdateOrderStatusUseCase(this.repository);

  Future<Resource<String>> execute({
    required String orderId,
    required String status,
    String? paymentType,
    double? upiAmount,
    double? cashAmount,
  }) {
    return repository.updateOrderStatus(
      orderId: orderId,
      status: status,
      paymentType: paymentType,
      upiAmount: upiAmount,
      cashAmount: cashAmount,
    );
  }
}
