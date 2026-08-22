import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/presentation/providers/transactions_provider.dart';

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
  const HistoryLoaded(this.transactions);
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

// ─── History Notifier ───────────────────────────────────────────

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;

  HistoryNotifier(this._ref) : super(const HistoryInitial());

  Future<void> loadTransactions() async {
    state = const HistoryLoading();
    try {
      final transactions = await _ref.read(transactionHistoryProvider.future);
      if (transactions.isEmpty) {
        state = const HistoryEmpty();
      } else {
        state = HistoryLoaded(transactions);
      }
    } catch (e) {
      state = HistoryError(e.toString());
    }
  }

  Future<void> refresh() async {
    await _ref.read(transactionsRefreshProvider)();
    _ref.invalidate(transactionHistoryProvider);
    await loadTransactions();
  }
}

final historyViewModelProvider =
    StateNotifierProvider.autoDispose<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});
