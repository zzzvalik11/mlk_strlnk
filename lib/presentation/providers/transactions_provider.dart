import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/transaction_remote_source.dart';
import 'package:telecom_dashboard/data/repositories/transaction_repository_impl.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/domain/repositories/transaction_repository.dart';
import 'package:telecom_dashboard/domain/usecases/transactions/get_transaction_history_usecase.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

// ─── Repository Provider ────────────────────────────────────────

final transactionRemoteSourceProvider =
    Provider<TransactionRemoteSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionRemoteSource(apiClient: apiClient);
});

final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    remoteSource: ref.watch(transactionRemoteSourceProvider),
  );
});

// ─── Use-Case Provider ──────────────────────────────────────────

final getTransactionHistoryUseCaseProvider =
    Provider<GetTransactionHistoryUseCase>((ref) {
  return GetTransactionHistoryUseCase(ref.watch(transactionRepositoryProvider));
});

// ─── Transaction History Provider ────────────────────────────────

/// Counter used to force-refresh the provider.
final _transactionRefreshCounterProvider = StateProvider.autoDispose<int>((ref) => 0);

final transactionHistoryProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  // Watch the refresh counter so calling [refreshTransactions] invalidates this.
  ref.watch(_transactionRefreshCounterProvider);

  final useCase = ref.watch(getTransactionHistoryUseCaseProvider);
  final result = await useCase.call();
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (page) => page.items,
  );
});

/// Increments the refresh counter, causing [transactionHistoryProvider]
/// to re-evaluate.
final transactionsRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(_transactionRefreshCounterProvider.notifier).state++;
  };
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
