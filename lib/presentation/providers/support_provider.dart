import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/support_remote_source.dart';
import 'package:telecom_dashboard/data/repositories/support_repository_impl.dart';
import 'package:telecom_dashboard/domain/entities/support_ticket.dart';
import 'package:telecom_dashboard/domain/repositories/support_repository.dart';
import 'package:telecom_dashboard/domain/usecases/support/create_ticket_usecase.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

// ─── Repository Provider ────────────────────────────────────────

final supportRemoteSourceProvider = Provider<SupportRemoteSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupportRemoteSource(apiClient: apiClient);
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepositoryImpl(
    remoteSource: ref.watch(supportRemoteSourceProvider),
    localSource: ref.watch(userLocalSourceProvider),
  );
});

// ─── Use-Case Provider ──────────────────────────────────────────

final createTicketUseCaseProvider = Provider<CreateTicketUseCase>((ref) {
  return CreateTicketUseCase(ref.watch(supportRepositoryProvider));
});

// ─── Create Ticket Provider ─────────────────────────────────────

final createTicketProvider = FutureProvider.autoDispose
    .family<SupportTicket, ({String subject, String description})>(
  (ref, params) async {
    final useCase = ref.watch(createTicketUseCaseProvider);
    final result = await useCase.call(
      subject: params.subject,
      description: params.description,
    );
    return result.fold(
      (Failure failure) => throw Exception(_failureMessage(failure)),
      (ticket) => ticket,
    );
  },
);

String _failureMessage(Failure failure) {
  return failure.when(
    network: (m) => m,
    server: (_, m) => m,
    validation: (m) => m,
    cache: (m) => m,
    unknown: (m) => m,
  );
}