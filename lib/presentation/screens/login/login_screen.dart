import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/validators.dart';
import 'package:telecom_dashboard/presentation/screens/login/login_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  String? _pinError;
  String? _passwordError;

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    _pinFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onLogin() {
    setState(() {
      _pinError = Validators.validatePin(_pinController.text);
      _passwordError = Validators.validatePassword(_passwordController.text);
    });

    if (_pinError != null || _passwordError != null) return;

    ref
        .read(loginViewModelProvider.notifier)
        .login(
          pin: _pinController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginViewModelProvider);
    final isSubmitting = formState is LoginFormSubmitting;

    // Listen for success and navigate.
    ref.listen<LoginFormState>(loginViewModelProvider, (prev, next) {
      if (next is LoginFormSuccess) {
        context.go(Routes.home);
      } else if (next is LoginFormNeedsMethodSelection) {
        context.go(Routes.authMethodSelection);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // ─── Logo ─────────────────
                Center(
                  child: Image.asset(
                    'assets/images/logo_act.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 48),
                // ─── PIN TextField ───────────────────────
                TextField(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_pinError != null) {
                      setState(() => _pinError = null);
                    }
                    ref.read(loginViewModelProvider.notifier).resetError();
                  },
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'ПИН',
                    hintText: '039103',
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.gray500,
                    ),
                    counterText: '',
                    errorText: _pinError,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(color: AppTheme.gray200),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(color: AppTheme.gray200),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(
                        color: AppTheme.orange500,
                        width: 2,
                      ),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(color: AppTheme.error),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(color: AppTheme.error, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ─── Password TextField ──────────────────
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                    ref.read(loginViewModelProvider.notifier).resetError();
                  },
                  onSubmitted: (_) => _onLogin(),
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    hintText: '123456',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.gray500,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.gray500,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    errorText: _passwordError,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(color: AppTheme.gray200),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(color: AppTheme.gray200),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(
                        color: AppTheme.orange500,
                        width: 2,
                      ),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(color: AppTheme.error),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderRadius: AppTheme.inputRadius,
                      borderSide: BorderSide(color: AppTheme.error, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ─── Server Error ───────────────────────
                if (formState is LoginFormError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      // ignore: unnecessary_cast
                      (formState as LoginFormError).message,
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                // ─── Login Button ───────────────────────
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange500,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.orange200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Войти',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                // ─── Support Link ───────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => context.push(Routes.support),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mail_outline_rounded,
                          size: 18,
                          color: AppTheme.info,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Написать в поддержку',
                            style: TextStyle(
                              color: AppTheme.info,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
