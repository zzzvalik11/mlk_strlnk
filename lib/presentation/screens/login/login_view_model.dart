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
  /// true if this is the first login and we should show auth method selection.
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
      print('[LOGIN] Step 1: reading authProvider.notifier');
      final authNotifier = _ref.read(authProvider.notifier);
      print('[LOGIN] Step 2: calling authNotifier.login');
      await authNotifier.login(pin: pin, password: password);
      print('[LOGIN] Step 3: reading authProvider state');
      final authState = _ref.read(authProvider);
      print('[LOGIN] Step 4: authState=$authState');
      if (authState.hasError) {
        final msg = authState.error.toString();
        state = LoginFormError(msg);
      } else if (authState.valueOrNull != null) {
        try {
          final localSource = _ref.read(userLocalSourceProvider);
          if (!localSource.isFirstLoginDone()) {
            await localSource.markFirstLoginDone();
            state = const LoginFormNeedsMethodSelection();
          } else {
            state = const LoginFormSuccess(isFirstLogin: false);
          }
        } catch (_) {
          state = const LoginFormSuccess(isFirstLogin: false);
        }
      } else {
        state = const LoginFormError('Неверный ПИН или пароль');
      }
    } catch (e, st) {
      print('[LOGIN] ERROR: $e');
      print('[LOGIN] STACK: $st');
      state = LoginFormError('$e\n\n$st');
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
