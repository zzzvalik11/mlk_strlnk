import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/presentation/providers/transactions_provider.dart';

// ─── Payment State ────────────────────────────────────────────

sealed class PaymentState {
  const PaymentState();
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentLoaded extends PaymentState {
  final List<Transaction> recentTransactions;
  const PaymentLoaded(this.recentTransactions);
}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
}

class PaymentEmpty extends PaymentState {
  const PaymentEmpty();
}

// ─── Payment Notifier ──────────────────────────────────────────

class PaymentNotifier extends StateNotifier<PaymentState> {
  final Ref _ref;

  PaymentNotifier(this._ref) : super(const PaymentInitial());

  Future<void> loadRecentTransactions() async {
    state = const PaymentLoading();
    try {
      final transactions = await _ref.read(transactionHistoryProvider.future);
      if (transactions.isEmpty) {
        state = const PaymentEmpty();
      } else {
        state = PaymentLoaded(transactions);
      }
    } catch (e) {
      state = PaymentError(e.toString());
    }
  }

  Future<void> refresh() async {
    _ref.invalidate(transactionHistoryProvider);
    await loadRecentTransactions();
  }
}

final paymentViewModelProvider =
    StateNotifierProvider.autoDispose<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref);
});
