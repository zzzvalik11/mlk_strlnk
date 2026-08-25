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

      final accounts = await _remoteSource.getAccounts();
      if (accounts.isEmpty) {
        return left(const Failure.server(
          statusCode: 404,
          message: 'Счета не найдены',
        ));
      }
      // Берём первый счёт для баланса
      final first = accounts.first;
      final model = BalanceModel(
        amount: (first['balance'] as num?)?.toDouble() ?? 0.0,
        currency: 'RUB',
        paidUntil: first['paid_until'] != null
            ? DateTime.tryParse(first['paid_until'] as String)
            : null,
        isPaid: (first['is_paid'] as bool?) ?? false,
        lastUpdated: DateTime.now(),
      );
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
        return right(_createMockBalance(amount: 500.0 + amount));
      }

      // Пополнение теперь через PaymentRepository (РСБ/СБП).
      // Этот метод оставлен для совместимости, но реальная логика
      // перенесена в PaymentRepository.getPayLink().
      return left(const Failure.unknown(
        message: 'Используйте PaymentRepository для пополнения',
      ));
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
      currency: 'RUB',
      paidUntil: DateTime(2025, 8, 15),
      isPaid: true,
      lastUpdated: DateTime.now(),
    );
  }
}
