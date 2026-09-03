import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, Page<Transaction>>> getHistory({
    int accountId = 1,
    String? dateFrom,
    String? dateTo,
  });
  Future<Either<Failure, Transaction>> getTransactionDetails(String id, {int accountId = 1});
}
