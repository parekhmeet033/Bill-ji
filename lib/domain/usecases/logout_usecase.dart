import '../../core/utils/resource.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Resource<void>> execute({String? deviceId}) {
    return repository.logout(deviceId: deviceId);
  }
}
