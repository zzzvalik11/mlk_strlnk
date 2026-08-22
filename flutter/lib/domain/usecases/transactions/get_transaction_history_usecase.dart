import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/domain/repositories/transaction_repository.dart';

class GetTransactionHistoryUseCase {
  final TransactionRepository _repository;

  const GetTransactionHistoryUseCase(this._repository);

  Future<Either<Failure, Page<Transaction>>> call({
    int page = 1,
    int limit = 20,
  }) {
    if (page < 1) page = 1;
    if (limit < 1) limit = 20;

    return _repository.getHistory(page: page, limit: limit);
  }
}
