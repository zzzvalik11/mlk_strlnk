import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, Page<Transaction>>> getHistory({
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, Transaction>> getTransactionDetails(String id);
}
