import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

/// Screen for quick re-login (PIN-only or Biometric).
/// Shown when the user has a valid 365-day token.
class QuickLoginScreen extends ConsumerStatefulWidget {
  const QuickLoginScreen({super.key});

  @override
  ConsumerState<QuickLoginScreen> createState() => _QuickLoginScreenState();
}

class _QuickLoginScreenState extends ConsumerState<QuickLoginScreen> {
  final _pinController = TextEditingController();
  final _localAuth = LocalAuthentication();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // If biometric, auto-trigger on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localSource = ref.read(userLocalSourceProvider);
      final method = localSource.getAuthMethod();
      if (method == AuthMethod.biometric) {
        _authenticateBiometric();
      }
    });
  }

  Future<void> _authenticateBiometric() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuth) {
        setState(() => _error = 'Биометрия не поддерживается на этом устройстве');
        return;
      }
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Войдите в Starlink',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuth) {
        await ref.read(authProvider.notifier).authenticateWithBiometric();
        final authState = ref.read(authProvider);
        if (!mounted) return;
        if (authState.valueOrNull != null) {
          context.go(Routes.home);
        } else if (authState.hasError) {
          setState(() => _error = authState.error.toString());
        }
      }
    } on PlatformException catch (e) {
      setState(() => _error = _mapBioError(e.message));
    }
  }

  String _mapBioError(String? msg) {
    if (msg?.contains('locked') == true ||
        msg?.contains('Lockout') == true) {
      return 'Слишком много попыток. Попробуйте позже.';
    }
    return 'Ошибка биометрии: $msg';
  }

  void _onPinSubmit() {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Введите ПИН-код');
      return;
    }
    ref.read(authProvider.notifier).authenticateWithPin(pin: pin);
  }

  @override
  Widget build(BuildContext context) {
    final localSource = ref.read(userLocalSourceProvider);
    final method = localSource.getAuthMethod() ?? AuthMethod.pin;

    // Listen for auth success
    ref.listen<AsyncValue>(authProvider, (prev, next) {
      if (next.valueOrNull != null) {
        context.go(Routes.home);
      } else if (next.hasError) {
        setState(() => _error = next.error.toString());
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo_act.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(flex: 1),
                // Auth method specific UI
                if (method == AuthMethod.pin) ...[
                  Text(
                    'Введите ПИН-код',
                    style: AppTheme.titleMedium
                        .copyWith(color: AppTheme.gray700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineLarge.copyWith(
                      fontSize: 32,
                      letterSpacing: 12,
                      color: AppTheme.gray900,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _onPinSubmit(),
                    decoration: InputDecoration(
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppTheme.gray400),
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.inputRadius,
                        borderSide: BorderSide(color: AppTheme.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppTheme.inputRadius,
                        borderSide: BorderSide(color: AppTheme.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppTheme.inputRadius,
                        borderSide: const BorderSide(
                            color: AppTheme.orange500, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onPinSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange500,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Приложите палец для входа',
                    style: TextStyle(
                        fontSize: 16, color: AppTheme.gray600),
                  ),
                  const SizedBox(height: 32),
                  // Big fingerprint button
                  GestureDetector(
                    onTap: _authenticateBiometric,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: AppTheme.elevatedShadow,
                      ),
                      child: const Icon(Icons.fingerprint,
                          size: 56, color: AppTheme.orange500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go(Routes.login),
                    child: Text(
                      'Войти с паролем',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.gray500),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(flex: 3),
                // Support link
                Center(
                  child: GestureDetector(
                    onTap: () => context.push(Routes.support),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mail_outline_rounded,
                            size: 18, color: AppTheme.info),
                        const SizedBox(width: 6),
                        Text(
                          'Написать в поддержку',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
