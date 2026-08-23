import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/balance_remote_source.dart';
import 'package:telecom_dashboard/data/repositories/balance_repository_impl.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';
import 'package:telecom_dashboard/domain/repositories/balance_repository.dart';
import 'package:telecom_dashboard/domain/usecases/balance/get_balance_usecase.dart';
import 'package:telecom_dashboard/domain/usecases/balance/top_up_usecase.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

// ─── Repository Provider ────────────────────────────────────────

final balanceRemoteSourceProvider = Provider<BalanceRemoteSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BalanceRemoteSource(apiClient: apiClient);
});

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepositoryImpl(
    remoteSource: ref.watch(balanceRemoteSourceProvider),
  );
});

// ─── Use-Case Providers ──────────────────────────────────────────

final getBalanceUseCaseProvider = Provider<GetBalanceUseCase>((ref) {
  return GetBalanceUseCase(ref.watch(balanceRepositoryProvider));
});

final topUpUseCaseProvider = Provider<TopUpUseCase>((ref) {
  return TopUpUseCase(ref.watch(balanceRepositoryProvider));
});

// ─── Balance Providers ───────────────────────────────────────────

final balanceProvider = FutureProvider.autoDispose<Balance>((ref) async {
  final useCase = ref.watch(getBalanceUseCaseProvider);
  final result = await useCase.call();
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (balance) => balance,
  );
});

final topUpProvider =
    FutureProvider.autoDispose.family<Balance, double>((ref, amount) async {
  final useCase = ref.watch(topUpUseCaseProvider);
  final result = await useCase.call(amount: amount);
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (balance) => balance,
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
