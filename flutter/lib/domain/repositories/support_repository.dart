import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/support_ticket.dart';

abstract class SupportRepository {
  Future<Either<Failure, SupportTicket>> createTicket({
    required String subject,
    required String description,
  });
  Future<Either<Failure, List<SupportTicket>>> getMyTickets();
  Future<Either<Failure, SupportTicket>> getTicketDetails(String id);
}
