import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/domain/entities/support_ticket.dart';
import 'package:telecom_dashboard/presentation/providers/support_provider.dart';

// ─── Support State ─────────────────────────────────────────

sealed class SupportFormState {
  const SupportFormState();
}

class SupportFormInitial extends SupportFormState {
  const SupportFormInitial();
}

class SupportFormSubmitting extends SupportFormState {
  const SupportFormSubmitting();
}

class SupportFormSuccess extends SupportFormState {
  final SupportTicket ticket;
  const SupportFormSuccess(this.ticket);
}

class SupportFormError extends SupportFormState {
  final String message;
  const SupportFormError(this.message);
}

// ─── Support Notifier ───────────────────────────────────────

class SupportNotifier extends StateNotifier<SupportFormState> {
  final Ref _ref;

  SupportNotifier(this._ref) : super(const SupportFormInitial());

  Future<void> submitTicket({
    required String pin,
    required String email,
    required String phone,
    required String message,
  }) async {
    if (pin.trim().isEmpty) {
      state = const SupportFormError('Введите ПИН-код');
      return;
    }
    if (email.trim().isEmpty) {
      state = const SupportFormError('Введите E-mail');
      return;
    }
    if (phone.trim().isEmpty) {
      state = const SupportFormError('Введите номер телефона');
      return;
    }
    if (message.trim().isEmpty) {
      state = const SupportFormError('Введите сообщение');
      return;
    }

    state = const SupportFormSubmitting();

    try {
      final ticket = await _ref.read(
        createTicketProvider((
          subject: 'ПИН ${pin.trim()}',
          description: 'От: ${email.trim()}\n'
              'Тел: ${phone.trim()}\n\n'
              '${message.trim()}',
        )).future,
      );
      state = SupportFormSuccess(ticket);
    } catch (e) {
      state = SupportFormError(e.toString());
    }
  }

  void reset() {
    state = const SupportFormInitial();
  }
}

final supportViewModelProvider =
    StateNotifierProvider.autoDispose<SupportNotifier, SupportFormState>((ref) {
  return SupportNotifier(ref);
});
