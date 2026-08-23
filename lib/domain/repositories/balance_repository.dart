import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';

abstract class BalanceRepository {
  Future<Either<Failure, Balance>> getBalance();
  Future<Either<Failure, Balance>> topUp(double amount, String method);
}
