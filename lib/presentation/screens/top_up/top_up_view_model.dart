import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/payment_link.dart';
import 'package:telecom_dashboard/domain/entities/payment_result.dart';
import 'package:telecom_dashboard/domain/usecases/payments/get_pay_link_usecase.dart';
import 'package:telecom_dashboard/presentation/providers/payment_provider.dart';

// ─── Top-Up State ───────────────────────────────────────────────

class TopUpState {
  final double? selectedAmount;
  final String customAmount;
  final PaymentMethod paymentMethod;
  final bool isSubmitting;
  final PaymentLink? paymentLink;
  final PaymentResult? paymentResult;
  final String? error;

  const TopUpState({
    this.selectedAmount,
    this.customAmount = '',
    this.paymentMethod = PaymentMethod.card,
    this.isSubmitting = false,
    this.paymentLink,
    this.paymentResult,
    this.error,
  });

  TopUpState copyWith({
    double? selectedAmount,
    String? customAmount,
    PaymentMethod? paymentMethod,
    bool? isSubmitting,
    PaymentLink? paymentLink,
    PaymentResult? paymentResult,
    String? error,
    bool clearSelected = false,
    bool clearLink = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return TopUpState(
      selectedAmount: clearSelected ? null : (selectedAmount ?? this.selectedAmount),
      customAmount: customAmount ?? this.customAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      paymentLink: clearLink ? null : (paymentLink ?? this.paymentLink),
      paymentResult: clearResult ? null : (paymentResult ?? this.paymentResult),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Top-Up Notifier ────────────────────────────────────────────

class TopUpNotifier extends StateNotifier<TopUpState> {
  final Ref _ref;

  TopUpNotifier(this._ref) : super(const TopUpState());

  static const List<double> quickAmounts = [100, 200, 500, 1000, 2000, 5000];
  /// ID первого лицевого счёта (заглушка — в реальном приложении
  /// берётся из профиля абонента).
  static const int _defaultAccountId = 123456;

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

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method, clearError: true);
  }

  double? get effectiveAmount {
    if (state.selectedAmount != null) return state.selectedAmount;
    if (state.customAmount.isNotEmpty) {
      return double.tryParse(state.customAmount);
    }
    return null;
  }

  /// Запросить ссылку на оплату у бэкенда.
  /// Бэкенд обратится к РСБ или СБП и вернёт URL/QR.
  Future<void> requestPayLink() async {
    final amount = effectiveAmount;
    if (amount == null || amount <= 0) {
      state = state.copyWith(error: 'Введите корректную сумму');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true, clearLink: true);

    try {
      final useCase = _ref.read(getPayLinkUseCaseProvider);
      final result = await useCase.call(
        accountId: _defaultAccountId,
        amount: amount,
        method: state.paymentMethod,
      );

      result.fold(
        (Failure failure) {
          state = state.copyWith(
            isSubmitting: false,
            error: _mapFailure(failure),
          );
        },
        (link) {
          state = state.copyWith(
            isSubmitting: false,
            paymentLink: link,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  /// Сбросить состояние после возврата из WebView.
  void onPaymentReturn() {
    state = state.copyWith(clearLink: true);
  }

  String _mapFailure(Failure failure) {
    return failure.when(
      network: (m) => 'Ошибка сети: $m',
      server: (code, m) => 'Ошибка сервера ($code): $m',
      validation: (m) => m,
      cache: (m) => m,
      unknown: (m) => m,
    );
  }
}

final topUpViewModelProvider =
    StateNotifierProvider.autoDispose<TopUpNotifier, TopUpState>((ref) {
  return TopUpNotifier(ref);
});
