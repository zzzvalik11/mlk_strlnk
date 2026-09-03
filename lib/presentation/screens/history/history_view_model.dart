import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/presentation/providers/transactions_provider.dart';

enum HistoryPeriod {
  week('Неделя'),
  month('Месяц'),
  quarter('Квартал'),
  year('Год'),
  custom('Произвольно'),
  all('Всё время');

  const HistoryPeriod(this.label);
  final String label;

  /// For custom period the caller must pass [customFrom].
  DateTime from({DateTime? customFrom}) {
    final now = DateTime.now();
    return switch (this) {
      HistoryPeriod.week => now.subtract(const Duration(days: 7)),
      HistoryPeriod.month => DateTime(now.year, now.month - 1, now.day),
      HistoryPeriod.quarter => DateTime(now.year, now.month - 3, now.day),
      HistoryPeriod.year => DateTime(now.year - 1, now.month, now.day),
      HistoryPeriod.custom => (customFrom ?? DateTime(now.year, now.month - 1, now.day)),
      HistoryPeriod.all => DateTime(2000),
    };
  }
}

// ─── History State ─────────────────────────────────────────────

sealed class HistoryState {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<Transaction> transactions;
  final HistoryPeriod period;
  final bool hasMore;
  final int currentPage;
  const HistoryLoaded(this.transactions, {this.period = HistoryPeriod.month, this.hasMore = false, this.currentPage = 1});

  HistoryLoaded copyWith({List<Transaction>? transactions, HistoryPeriod? period, bool? hasMore, int? currentPage}) {
    return HistoryLoaded(
      transactions ?? this.transactions,
      period: period ?? this.period,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
}

class HistoryEmpty extends HistoryState {
  final HistoryPeriod period;
  const HistoryEmpty({this.period = HistoryPeriod.month});
}

// ─── History Notifier ───────────────────────────────────────────

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;
  HistoryPeriod _period = HistoryPeriod.month;
  DateTimeRange? _customRange;
  int _page = 1;
  bool _hasMore = false;
  List<Transaction> _allTransactions = [];

  HistoryNotifier(this._ref) : super(const HistoryInitial());

  HistoryPeriod get period => _period;
  DateTimeRange? get customRange => _customRange;

  void setPeriod(HistoryPeriod newPeriod) {
    if (newPeriod == _period) return;
    _period = newPeriod;
    _page = 1;
    _allTransactions = [];
    loadTransactions();
  }

  void setCustomRange(DateTimeRange range) {
    _period = HistoryPeriod.custom;
    _customRange = range;
    _page = 1;
    _allTransactions = [];
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = const HistoryLoading();
    try {
      final transactions = await _ref.read(transactionHistoryProvider.future);
      final from = _period.from(customFrom: _customRange?.start);
      _allTransactions = transactions.where((t) => !t.date.isBefore(from)).toList();
      _allTransactions.sort((a, b) => b.date.compareTo(a.date));
      _hasMore = _allTransactions.length > _page * 10;
      final pageItems = _allTransactions.take(_page * 10).toList();
      if (pageItems.isEmpty) {
        state = HistoryEmpty(period: _period);
      } else {
        state = HistoryLoaded(pageItems, period: _period, hasMore: _hasMore, currentPage: _page);
      }
    } catch (e) {
      state = HistoryError(e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state is! HistoryLoaded) return;
    final loaded = state as HistoryLoaded;
    if (!loaded.hasMore) return;
    _page++;
    _hasMore = _allTransactions.length > _page * 10;
    final pageItems = _allTransactions.take(_page * 10).toList();
    state = HistoryLoaded(pageItems, period: _period, hasMore: _hasMore, currentPage: _page);
  }

  Future<void> refresh() async {
    await _ref.read(transactionsRefreshProvider)();
    _ref.invalidate(transactionHistoryProvider);
    _page = 1;
    _allTransactions = [];
    await loadTransactions();
  }
}

final historyViewModelProvider =
    StateNotifierProvider.autoDispose<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});
