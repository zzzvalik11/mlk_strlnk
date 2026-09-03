import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/service_remote_source.dart';
import 'package:telecom_dashboard/data/repositories/service_repository_impl.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';
import 'package:telecom_dashboard/domain/repositories/service_repository.dart';
import 'package:telecom_dashboard/domain/usecases/services/get_active_services_usecase.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

// ─── Repository Provider ────────────────────────────────────────

final serviceRemoteSourceProvider = Provider<ServiceRemoteSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServiceRemoteSource(apiClient: apiClient);
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(
    remoteSource: ref.watch(serviceRemoteSourceProvider),
    localSource: ref.watch(userLocalSourceProvider),
  );
});

// ─── Use-Case Provider ──────────────────────────────────────────

final getActiveServicesUseCaseProvider =
    Provider<GetActiveServicesUseCase>((ref) {
  return GetActiveServicesUseCase(ref.watch(serviceRepositoryProvider));
});

// ─── Active Services Provider ────────────────────────────────────

final activeServicesProvider =
    FutureProvider.autoDispose<List<Service>>((ref) async {
  final useCase = ref.watch(getActiveServicesUseCaseProvider);
  final result = await useCase.call();
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (services) => services,
  );
});

String _failureMessage(Failure failure) {
  return failure.when(
    network: (m) => m,
    server: (_, m) => m,
    validation: (m) => m,
    cache: (m) => m,
    unknown: (m) => m,
  );
}