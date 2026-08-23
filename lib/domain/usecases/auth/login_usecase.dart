import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/core/utils/validators.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';
import 'package:telecom_dashboard/domain/repositories/user_repository.dart';

class LoginUseCase {
  final UserRepository _repository;

  const LoginUseCase(this._repository);

  Future<Either<Failure, User>> call({
    required String pin,
    String? password,
  }) async {
    final pinError = validatePin(pin);
    if (pinError != null) {
      return left(Failure.validation(message: pinError));
    }

    if (password != null) {
      final passwordError = validatePassword(password);
      if (passwordError != null) {
        return left(Failure.validation(message: passwordError));
      }
    }

    return _repository.login(pin);
  }
}
