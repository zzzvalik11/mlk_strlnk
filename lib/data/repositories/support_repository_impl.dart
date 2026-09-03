import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/support_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/support_ticket.dart';
import 'package:telecom_dashboard/domain/repositories/support_repository.dart';

/// [SupportRepository] implementation backed by the remote API.
/// Returns mock data when the current user is the test user (039103).
class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteSource _remoteSource;
  final UserLocalSource _localSource;

  SupportRepositoryImpl({
    required this._remoteSource,
    required this._localSource,
  });

  @override
  Future<Either<Failure, SupportTicket>> createTicket({
    required String subject,
    required String description,
  }) async {
    try {
      if (_localSource.isMockUser()) {
        final ticket = SupportTicket(
          id: 'stk_${DateTime.now().millisecondsSinceEpoch}',
          subject: subject,
          description: description,
          status: TicketStatus.open,
          createdAt: DateTime.now(),
          replyCount: 0,
        );
        return right(ticket);
      }

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
      if (_localSource.isMockUser()) {
        return right(_createMockTickets());
      }

      final models = await _remoteSource.getTickets();
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
      if (_localSource.isMockUser()) {
        final all = _createMockTickets();
        final match = all.where((t) => t.id == id).firstOrNull;
        if (match == null) {
          return left(
            const Failure.server(
              statusCode: 404,
              message: 'Обращение не найдено',
            ),
          );
        }
        return right(match);
      }

      final models = await _remoteSource.getTickets();
      final match = models.where((m) => m.id == id).firstOrNull;
      if (match == null) {
        return left(
          const Failure.server(
            statusCode: 404,
            message: 'Обращение не найдено',
          ),
        );
      }
      return right(match.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  // ── Mock tickets data ───────────────────────────────────────

  List<SupportTicket> _createMockTickets() {
    return [
      SupportTicket(
        id: 'stk1',
        subject: 'Низкая скорость интернета',
        description: 'Вечером скорость падает до 10 Мбит/с вместо 100.',
        status: TicketStatus.inProgress,
        createdAt: DateTime(2025, 7, 5),
        replyCount: 2,
      ),
      SupportTicket(
        id: 'stk2',
        subject: 'Вопрос по тарифу',
        description: 'Хочу перейти на тариф «Максимум», как это сделать?',
        status: TicketStatus.resolved,
        createdAt: DateTime(2025, 6, 20),
        replyCount: 3,
      ),
    ];
  }
}
