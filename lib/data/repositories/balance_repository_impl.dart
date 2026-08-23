import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/balance_remote_source.dart';
import 'package:telecom_dashboard/data/models/balance_model.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';
import 'package:telecom_dashboard/domain/repositories/balance_repository.dart';

/// [BalanceRepository] implementation backed by the remote API.
/// Returns mock data when the current user is the test user (039103).
class BalanceRepositoryImpl implements BalanceRepository {
  final BalanceRemoteSource _remoteSource;
  final UserLocalSource _localSource;

  BalanceRepositoryImpl({
    required BalanceRemoteSource remoteSource,
    required UserLocalSource localSource,
  })  : _remoteSource = remoteSource,
        _localSource = localSource;

  @override
  Future<Either<Failure, Balance>> getBalance() async {
    try {
      // Mock data for test user — no network calls
      if (_localSource.isMockUser()) {
        return right(_createMockBalance());
      }

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
      if (_localSource.isMockUser()) {
        // Just return a mock balance with updated amount
        return right(_createMockBalance(amount: 500.0 + amount));
      }

      final result = await _remoteSource.topUp(amount);
      final newBalanceValue = (result['newBalance'] as num).toDouble();
      final model = await _remoteSource.getBalance();
      return right(model.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  // ── Mock balance data ──────────────────────────────────────────

  Balance _createMockBalance({double? amount}) {
    return Balance(
      amount: amount ?? 500.0,
      currency: '₽',
      paidUntil: DateTime(2025, 8, 15),
      isPaid: true,
      lastUpdated: DateTime.now(),
    );
  }
}
