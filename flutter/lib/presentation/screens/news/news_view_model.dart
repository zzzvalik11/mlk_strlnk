import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';
import 'package:telecom_dashboard/presentation/providers/news_provider.dart';

// ─── News State ───────────────────────────────────────────────

sealed class NewsListState {
  const NewsListState();
}

class NewsListInitial extends NewsListState {
  const NewsListInitial();
}

class NewsListLoading extends NewsListState {
  const NewsListLoading();
}

class NewsListLoaded extends NewsListState {
  final List<NewsItem> items;
  const NewsListLoaded(this.items);
}

class NewsListError extends NewsListState {
  final String message;
  const NewsListError(this.message);
}

class NewsListEmpty extends NewsListState {
  const NewsListEmpty();
}

// ─── News List Notifier ───────────────────────────────────────

class NewsListNotifier extends StateNotifier<NewsListState> {
  final Ref _ref;

  NewsListNotifier(this._ref) : super(const NewsListInitial());

  Future<void> loadNews() async {
    state = const NewsListLoading();
    try {
      final items = await _ref.read(newsListProvider.future);
      if (items.isEmpty) {
        state = const NewsListEmpty();
      } else {
        state = NewsListLoaded(items);
      }
    } catch (e) {
      state = NewsListError(e.toString());
    }
  }

  Future<void> refresh() async {
    await _ref.read(newsRefreshProvider)();
    _ref.invalidate(newsListProvider);
    await loadNews();
  }
}

final newsListViewModelProvider =
    StateNotifierProvider.autoDispose<NewsListNotifier, NewsListState>((ref) {
  return NewsListNotifier(ref);
});
