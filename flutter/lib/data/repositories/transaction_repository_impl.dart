import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/transaction_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/domain/repositories/transaction_repository.dart';

/// [TransactionRepository] implementation backed by the remote API.
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteSource _remoteSource;

  TransactionRepositoryImpl({required TransactionRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<Either<Failure, Page<Transaction>>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final models = await _remoteSource.getTransactionHistory(
        page: page,
        limit: limit,
      );
      final entities = models.map((m) => m.toDomain()).toList();

      // The mock API returns a flat list.  Wrap it in a [Page] object.
      final total = entities.length;
      final domainPage = Page<Transaction>(
        items: entities,
        total: total,
        page: page,
        limit: limit,
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
  Future<Either<Failure, Transaction>> getTransactionDetails(String id) async {
    try {
      // The mock API does not expose a single-transaction endpoint.
      // Fetch the full list and locate by id.
      final models = await _remoteSource.getTransactionHistory();
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
}
