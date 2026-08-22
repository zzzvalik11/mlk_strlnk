import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/support_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/support_ticket.dart';
import 'package:telecom_dashboard/domain/repositories/support_repository.dart';

/// [SupportRepository] implementation backed by the remote API.
class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteSource _remoteSource;

  SupportRepositoryImpl({required SupportRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<Either<Failure, SupportTicket>> createTicket({
    required String subject,
    required String description,
  }) async {
    try {
      final model = await _remoteSource.createTicket(
        subject: subject,
        description: description,
      );
      return right(model.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SupportTicket>>> getMyTickets() async {
    try {
      final models = await _remoteSource.getMyTickets();
      return right(models.map((m) => m.toDomain()).toList());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupportTicket>> getTicketDetails(String id) async {
    try {
      // The mock API does not expose a single-ticket endpoint.
      // Fetch all tickets and locate by id.
      final models = await _remoteSource.getMyTickets();
      final match = models.where((m) => m.id == id).firstOrNull;
      if (match == null) {
        return left(
          Failure.server(statusCode: 404, message: 'Обращение не найдено'),
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
