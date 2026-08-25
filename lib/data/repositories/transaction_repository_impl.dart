import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/transaction_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/domain/repositories/transaction_repository.dart';

/// [TransactionRepository] implementation backed by the remote API.
/// Returns mock data when the current user is the test user (039103).
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteSource _remoteSource;
  final UserLocalSource _localSource;

  TransactionRepositoryImpl({
    required TransactionRemoteSource remoteSource,
    required UserLocalSource localSource,
  })  : _remoteSource = remoteSource,
        _localSource = localSource;

  @override
  Future<Either<Failure, Page<Transaction>>> getHistory({
    int accountId = 1,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      if (_localSource.isMockUser()) {
        final items = _createMockTransactions();
        return right(Page<Transaction>(
          items: items,
          total: items.length,
          page: 1,
          limit: items.length,
          hasMore: false,
        ));
      }

      final models = await _remoteSource.getTransactionHistory(
        accountId: accountId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      final entities = models.map((m) => m.toDomain()).toList();
      final domainPage = Page<Transaction>(
        items: entities,
        total: entities.length,
        page: 1,
        limit: entities.length,
        hasMore: false,
      );
      return right(domainPage);
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> getTransactionDetails(String id, {int accountId = 1}) async {
    try {
      if (_localSource.isMockUser()) {
        final all = _createMockTransactions();
        final match = all.where((t) => t.id == id).firstOrNull;
        if (match == null) {
          return left(const Failure.server(statusCode: 404, message: 'Транзакция не найдена'));
        }
        return right(match);
      }

      final models = await _remoteSource.getTransactionHistory(accountId: accountId);
      final match = models.where((m) => m.id == id).firstOrNull;
      if (match == null) {
        return left(
          Failure.server(statusCode: 404, message: 'Транзакция не найдена'),
        );
      }
      return right(match.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  // ── Mock transactions data ───────────────────────────────────

  List<Transaction> _createMockTransactions() {
    return [
      Transaction(
        id: 't1',
        type: TransactionType.payment,
        amount: -890.0,
        description: 'Оплата тарифа «Интернет 100»',
        date: DateTime(2025, 7, 1),
        status: TransactionStatus.success,
      ),
      Transaction(
        id: 't2',
        type: TransactionType.topUp,
        amount: 1000.0,
        description: 'Пополнение через Сбербанк',
        date: DateTime(2025, 6, 28),
        status: TransactionStatus.success,
      ),
      Transaction(
        id: 't3',
        type: TransactionType.payment,
        amount: -890.0,
        description: 'Оплата тарифа «Интернет 100»',
        date: DateTime(2025, 6, 1),
        status: TransactionStatus.success,
      ),
      Transaction(
        id: 't4',
        type: TransactionType.bonus,
        amount: 200.0,
        description: 'Бонус за обращение в поддержку',
        date: DateTime(2025, 5, 15),
        status: TransactionStatus.success,
      ),
    ];
  }
}
