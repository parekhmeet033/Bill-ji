import '../../core/utils/resource.dart';
import '../repositories/order_repository.dart';

class ForgotPinUseCase {
  final OrderRepository repository;

  ForgotPinUseCase(this.repository);

  Future<Resource<void>> execute({required String oldPin, required String newPin}) {
    return repository.forgotPin(oldPin: oldPin, newPin: newPin);
  }
}
