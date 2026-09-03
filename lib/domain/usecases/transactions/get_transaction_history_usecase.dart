import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/domain/repositories/transaction_repository.dart';

class GetTransactionHistoryUseCase {
  final TransactionRepository _repository;

  const GetTransactionHistoryUseCase(this._repository);

  Future<Either<Failure, Page<Transaction>>> call({
    int accountId = 1,
    String? dateFrom,
    String? dateTo,
  }) {
    return _repository.getHistory(
      accountId: accountId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
