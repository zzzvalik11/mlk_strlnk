import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

// ─── Login State ──────────────────────────────────────────

sealed class LoginFormState {
  const LoginFormState();
}

class LoginFormInitial extends LoginFormState {
  const LoginFormInitial();
}

class LoginFormSubmitting extends LoginFormState {
  const LoginFormSubmitting();
}

class LoginFormError extends LoginFormState {
  final String message;
  const LoginFormError(this.message);
}

class LoginFormSuccess extends LoginFormState {
  final bool isFirstLogin;
  const LoginFormSuccess({this.isFirstLogin = false});
}

class LoginFormNeedsMethodSelection extends LoginFormState {
  const LoginFormNeedsMethodSelection();
}

// ─── Login Notifier ────────────────────────────────────────

class LoginNotifier extends StateNotifier<LoginFormState> {
  final Ref _ref;

  LoginNotifier(this._ref) : super(const LoginFormInitial());

  Future<void> login({
    required String pin,
    required String password,
  }) async {
    state = const LoginFormSubmitting();

    try {
      await _ref.read(authProvider.notifier).login(pin: pin, password: password);

      final authState = _ref.read(authProvider);
      if (authState.hasError) {
        final msg = authState.error.toString();
        state = LoginFormError(msg);
      } else if (authState.valueOrNull != null) {
        final localSource = _ref.read(userLocalSourceProvider);
        if (!localSource.isFirstLoginDone()) {
          await localSource.markFirstLoginDone();
          state = const LoginFormNeedsMethodSelection();
        } else {
          state = const LoginFormSuccess(isFirstLogin: false);
        }
      } else {
        state = const LoginFormError('Неверный ПИН или пароль');
      }
    } catch (e) {
      state = LoginFormError(e.toString());
    }
  }

  void resetError() {
    if (state is LoginFormError) {
      state = const LoginFormInitial();
    }
  }
}

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, LoginFormState>((ref) {
  return LoginNotifier(ref);
});
