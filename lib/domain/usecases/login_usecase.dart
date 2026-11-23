import '../../core/utils/resource.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Resource<UserEntity>> execute(
    String email,
    String password, {
    String? deviceId,
    String? deviceType,
    String? fcmToken,
  }) {
    return repository.login(
      email,
      password,
      deviceId: deviceId,
      deviceType: deviceType,
      fcmToken: fcmToken,
    );
  }
}
