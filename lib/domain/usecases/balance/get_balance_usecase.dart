import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';
import 'package:telecom_dashboard/domain/repositories/balance_repository.dart';

class GetBalanceUseCase {
  final BalanceRepository _repository;

  const GetBalanceUseCase(this._repository);

  Future<Either<Failure, Balance>> call() {
    return _repository.getBalance();
  }
}
