import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/balance_remote_source.dart';
import 'package:telecom_dashboard/data/models/balance_model.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';
import 'package:telecom_dashboard/domain/repositories/balance_repository.dart';

/// [BalanceRepository] implementation backed by the remote API.
class BalanceRepositoryImpl implements BalanceRepository {
  final BalanceRemoteSource _remoteSource;

  BalanceRepositoryImpl({required BalanceRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<Either<Failure, Balance>> getBalance() async {
    try {
      final model = await _remoteSource.getBalance();
      return right(model.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Balance>> topUp(double amount, String method) async {
    try {
      final result = await _remoteSource.topUp(amount);
      // The mock API returns { "newBalance": ... }
      final newBalanceValue =
          (result['newBalance'] as num).toDouble();
      // Re-fetch to get a full BalanceModel with all fields
      final model = await _remoteSource.getBalance();
      return right(model.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
