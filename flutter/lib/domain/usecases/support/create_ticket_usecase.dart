import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/support_ticket.dart';
import 'package:telecom_dashboard/domain/repositories/support_repository.dart';

class CreateTicketUseCase {
  final SupportRepository _repository;

  const CreateTicketUseCase(this._repository);

  Future<Either<Failure, SupportTicket>> call({
    required String subject,
    required String description,
  }) {
    if (subject.trim().isEmpty) {
      return Future.value(
        left(Failure.validation(message: 'Тема обращения не может быть пустой')),
      );
    }

    if (description.trim().isEmpty) {
      return Future.value(
        left(Failure.validation(message: 'Описание обращения не может быть пустым')),
      );
    }

    return _repository.createTicket(
      subject: subject.trim(),
      description: description.trim(),
    );
  }
}
