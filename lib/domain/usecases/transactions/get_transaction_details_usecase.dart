import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/domain/repositories/transaction_repository.dart';

class GetTransactionDetailsUseCase {
  final TransactionRepository _repository;

  const GetTransactionDetailsUseCase(this._repository);

  Future<Either<Failure, Transaction>> call({required String id}) {
    if (id.isEmpty) {
      return Future.value(
        left(Failure.validation(message: 'ID транзакции не может быть пустым')),
      );
    }

    return _repository.getTransactionDetails(id);
  }
}
