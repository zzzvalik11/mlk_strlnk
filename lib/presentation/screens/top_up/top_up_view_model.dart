import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';
import 'package:telecom_dashboard/presentation/providers/balance_provider.dart';

// ─── Top-Up State ───────────────────────────────────────────────

class TopUpState {
  final double? selectedAmount;
  final String customAmount;
  final bool isSubmitting;
  final Balance? result;
  final String? error;

  const TopUpState({
    this.selectedAmount,
    this.customAmount = '',
    this.isSubmitting = false,
    this.result,
    this.error,
  });

  TopUpState copyWith({
    double? selectedAmount,
    String? customAmount,
    bool? isSubmitting,
    Balance? result,
    String? error,
    bool clearSelected = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return TopUpState(
      selectedAmount: clearSelected ? null : (selectedAmount ?? this.selectedAmount),
      customAmount: customAmount ?? this.customAmount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Top-Up Notifier ────────────────────────────────────────────

class TopUpNotifier extends StateNotifier<TopUpState> {
  final Ref _ref;

  TopUpNotifier(this._ref) : super(const TopUpState());

  static const List<double> quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  void selectQuickAmount(double amount) {
    state = state.copyWith(
      selectedAmount: amount,
      customAmount: '',
      clearError: true,
    );
  }

  void updateCustomAmount(String value) {
    state = state.copyWith(
      customAmount: value,
      clearSelected: true,
      clearError: true,
    );
  }

  double? get effectiveAmount {
    if (state.selectedAmount != null) return state.selectedAmount;
    if (state.customAmount.isNotEmpty) {
      return double.tryParse(state.customAmount);
    }
    return null;
  }

  Future<void> submitTopUp() async {
    final amount = effectiveAmount;
    if (amount == null || amount <= 0) {
      state = state.copyWith(error: 'Введите корректную сумму');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final newBalance = await _ref.read(topUpProvider(amount).future);
      state = state.copyWith(
        isSubmitting: false,
        result: newBalance,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }
}

final topUpViewModelProvider =
    StateNotifierProvider.autoDispose<TopUpNotifier, TopUpState>((ref) {
  return TopUpNotifier(ref);
});
