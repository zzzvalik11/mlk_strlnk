import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/news_remote_source.dart';
import 'package:telecom_dashboard/data/repositories/news_repository_impl.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';
import 'package:telecom_dashboard/domain/repositories/news_repository.dart';
import 'package:telecom_dashboard/domain/usecases/news/get_news_by_id_usecase.dart';
import 'package:telecom_dashboard/domain/usecases/news/get_news_list_usecase.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

// ─── Repository Provider ────────────────────────────────────────

final newsRemoteSourceProvider = Provider<NewsRemoteSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NewsRemoteSource(apiClient: apiClient);
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepositoryImpl(
    remoteSource: ref.watch(newsRemoteSourceProvider),
  );
});

// ─── Use-Case Providers ─────────────────────────────────────────

final getNewsListUseCaseProvider = Provider<GetNewsListUseCase>((ref) {
  return GetNewsListUseCase(ref.watch(newsRepositoryProvider));
});

final getNewsByIdUseCaseProvider = Provider<GetNewsByIdUseCase>((ref) {
  return GetNewsByIdUseCase(ref.watch(newsRepositoryProvider));
});

// ─── News List Provider ─────────────────────────────────────────

/// Counter used to force-refresh the provider.
final _newsRefreshCounterProvider = StateProvider.autoDispose<int>((ref) => 0);

final newsListProvider = FutureProvider.autoDispose<List<NewsItem>>((ref) async {
  ref.watch(_newsRefreshCounterProvider);

  final useCase = ref.watch(getNewsListUseCaseProvider);
  final result = await useCase.call();
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (page) => page.items,
  );
});

/// Increments the refresh counter, causing [newsListProvider] to re-evaluate.
final newsRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(_newsRefreshCounterProvider.notifier).state++;
  };
});

// ─── News Detail Provider ───────────────────────────────────────

final newsDetailProvider =
    FutureProvider.autoDispose.family<NewsItem, String>((ref, id) async {
  final useCase = ref.watch(getNewsByIdUseCaseProvider);
  final result = await useCase.call(id: id);
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (news) => news,
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
