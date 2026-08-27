import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

class AuthMethodSelectionScreen extends ConsumerWidget {
  const AuthMethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo_act.png',
                        width: 220,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Выберите способ входа',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Для быстрого входа в приложение',
                        style: TextStyle(fontSize: 15, color: AppTheme.gray500),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
                // PIN option
                _OptionCard(
                  icon: Icons.dialpad_rounded,
                  title: 'ПИН-код',
                  subtitle: 'Ввод 6-значного ПИН при входе',
                  onTap: () => _selectMethod(context, ref, AuthMethod.pin),
                ),
                const SizedBox(height: 16),
                // Biometric option
                _OptionCard(
                  icon: Icons.fingerprint,
                  title: 'Отпечаток пальца',
                  subtitle: 'Быстрый вход по биометрии',
                  onTap: () =>
                      _selectMethod(context, ref, AuthMethod.biometric),
                ),
                const Spacer(flex: 3),
                // Skip
                TextButton(
                  onPressed: () => context.go(Routes.home),
                  child: Text(
                    'Выбрать позже',
                    style:
                        AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
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

  Future<void> _selectMethod(
    BuildContext context,
    WidgetRef ref,
    AuthMethod method,
  ) async {
    final localSource = ref.read(userLocalSourceProvider);
    await localSource.saveAuthMethod(method);
    await localSource.markFirstLoginDone();
    if (context.mounted) {
      context.go(Routes.home);
    }
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.orange50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: AppTheme.orange500),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.gray500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppTheme.gray400, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
