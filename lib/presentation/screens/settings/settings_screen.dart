import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/responsive.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AuthMethod? _currentMethod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentMethod = ref.read(userLocalSourceProvider).getAuthMethod();
  }

  Future<void> _changeAuthMethod(AuthMethod method) async {
    setState(() => _saving = true);
    final localSource = ref.read(userLocalSourceProvider);
    await localSource.saveAuthMethod(method);
    setState(() {
      _currentMethod = method;
      _saving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Способ входа изменён'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.orange50,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: AppTheme.orange50,
        foregroundColor: AppTheme.gray900,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Auth Method Section ─────────────
              const Text(
                'Способ быстрого входа',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _AuthMethodTile(
                        icon: Icons.dialpad_rounded,
                        title: 'ПИН-код',
                        subtitle: 'Ввод 6-значного ПИН',
                        selected: _currentMethod == AuthMethod.pin,
                        enabled: !_saving,
                        onTap: () => _changeAuthMethod(AuthMethod.pin),
                      ),
                      const Divider(height: 1, indent: 72),
                      _AuthMethodTile(
                        icon: Icons.fingerprint,
                        title: 'Отпечаток пальца',
                        subtitle: 'Биометрический вход',
                        selected: _currentMethod == AuthMethod.biometric,
                        enabled: !_saving,
                        onTap: () => _changeAuthMethod(AuthMethod.biometric),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ─── Logout ───────────────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
                    title: const Text(
                      'Выйти из аккаунта',
                      style: TextStyle(
                          color: AppTheme.error, fontWeight: FontWeight.w500),
                    ),
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ─── App Info ─────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'Starlink',
                      style: AppTheme.titleMedium.copyWith(color: AppTheme.gray400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Версия 1.0.0',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.gray400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AuthMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.orange50
              : AppTheme.gray200.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 24,
          color: selected ? AppTheme.orange500 : AppTheme.gray500,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppTheme.orange500, size: 24)
          : const Icon(Icons.circle_outlined, color: AppTheme.gray300, size: 24),
      onTap: enabled ? onTap : null,
    );
  }
}
