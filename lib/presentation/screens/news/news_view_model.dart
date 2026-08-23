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
  final int page;
  final bool hasMore;
  const NewsListLoaded(this.items, {this.page = 1, this.hasMore = false});
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
  static const int _pageSize = 10;
  int _currentPage = 1;
  bool _hasMore = false;

  NewsListNotifier(this._ref) : super(const NewsListInitial());

  Future<void> loadNews() async {
    state = const NewsListLoading();
    try {
      final page = await _ref.read(newsListProvider.future);
      final allItems = page.items;
      _hasMore = page.hasMore;
      final visibleItems = allItems.take(_currentPage * _pageSize).toList();
      if (visibleItems.isEmpty) {
        state = const NewsListEmpty();
      } else {
        state = NewsListLoaded(visibleItems, page: _currentPage, hasMore: _hasMore);
      }
    } catch (e) {
      state = NewsListError(e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state is! NewsListLoaded) return;
    _currentPage++;
    try {
      final page = await _ref.read(newsListProvider.future);
      final allItems = page.items;
      _hasMore = page.hasMore;
      final visibleItems = allItems.take(_currentPage * _pageSize).toList();
      state = NewsListLoaded(visibleItems, page: _currentPage, hasMore: _hasMore);
    } catch (e) {
      // keep current state on error
    }
  }

  Future<void> refresh() async {
    await _ref.read(newsRefreshProvider)();
    _ref.invalidate(newsListProvider);
    _currentPage = 1;
    await loadNews();
  }
}

final newsListViewModelProvider =
    StateNotifierProvider.autoDispose<NewsListNotifier, NewsListState>((ref) {
  return NewsListNotifier(ref);
});
