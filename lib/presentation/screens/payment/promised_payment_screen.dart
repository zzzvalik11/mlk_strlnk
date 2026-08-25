import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';

class PromisedPaymentScreen extends ConsumerStatefulWidget {
  const PromisedPaymentScreen({super.key});

  @override
  ConsumerState<PromisedPaymentScreen> createState() => _PromisedPaymentScreenState();
}

class _PromisedPaymentScreenState extends ConsumerState<PromisedPaymentScreen> {
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBackButton: true, title: 'Обещанный платёж'),
            Expanded(
              child: SingleChildScrollView(
                padding: AppTheme.screenPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Info card
                      Container(
                        padding: AppTheme.cardPadding,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.cardRadius,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Обещанный платёж',
                                    style: AppTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Обещанный платёж позволяет продлить срок оплаты услуг на 3 дня при недостаточном балансе. Услуга доступна не чаще одного раза в месяц.',
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Conditions
                      Container(
                        padding: AppTheme.cardPadding,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.cardRadius,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Условия', style: AppTheme.titleMedium),
                            const SizedBox(height: 12),
                            _ConditionItem(icon: Icons.check_circle_outline_rounded, text: 'Баланс менее 100 ₽'),
                            _ConditionItem(icon: Icons.check_circle_outline_rounded, text: 'Нет предыдущих обещанных платежей в этом месяце'),
                            _ConditionItem(icon: Icons.check_circle_outline_rounded, text: 'Аккаунт не заблокирован'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.08),
                            borderRadius: AppTheme.cardRadius,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 16),
                      // Success state
                      if (_isSuccess) ...[
                        Container(
                          padding: AppTheme.cardPadding,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.08),
                            borderRadius: AppTheme.cardRadius,
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.success),
                              const SizedBox(height: 12),
                              Text('Обещанный платёж активирован', style: AppTheme.titleMedium, textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text(
                                'Срок оплаты продлён на 3 дня. Пожалуйста, пополните баланс вовремя.',
                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Submit button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _activatePromisedPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orange500,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.orange200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Активировать',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activatePromisedPayment() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    // Имитация запроса к серверу
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isSuccess = true;
    });
  }
}

class _ConditionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConditionItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray700)),
          ),
        ],
      ),
    );
  }
}
