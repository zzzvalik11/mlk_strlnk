import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';
import 'package:telecom_dashboard/domain/repositories/balance_repository.dart';

class TopUpUseCase {
  final BalanceRepository _repository;

  const TopUpUseCase(this._repository);

  Future<Either<Failure, Balance>> call({
    required double amount,
    String method = 'card',
  }) {
    if (amount <= 0) {
      return Future.value(
        left(
          const Failure.validation(
            message: 'Сумма пополнения должна быть больше нуля',
          ),
        ),
      );
    }

    return _repository.topUp(amount, method);
  }
}
