import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';

class PromisedPaymentScreen extends ConsumerStatefulWidget {
  const PromisedPaymentScreen({super.key});

  @override
  ConsumerState<PromisedPaymentScreen> createState() =>
      _PromisedPaymentScreenState();
}

class _PromisedPaymentScreenState extends ConsumerState<PromisedPaymentScreen> {
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  /// Selected period in days (7..90), default 3 days (mapped to 3).
  /// But user can choose 7-90. We start at 7.
  double _selectedDays = 7;

  DateTime get _startDate => DateTime.now().add(const Duration(days: 1));
  DateTime get _endDate =>
      _startDate.add(Duration(days: _selectedDays.round()));

  String _formatDate(DateTime d) => DateFormat('dd.MM.yyyy', 'ru').format(d);

  @override
  Widget build(BuildContext context) {
    final days = _selectedDays.round();

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
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppTheme.info,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Обещанный платёж',
                                    style: AppTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Обещанный платёж позволяет продлить срок оплаты услуг при недостаточном балансе. Выберите желаемый период отложенной оплаты.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Period selection card
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
                            const Text(
                              'Выбор периода',
                              style: AppTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'С завтрашнего дня ($_formatDate(_startDate))',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.gray500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Slider
                            Row(
                              children: [
                                Text(
                                  '7',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.gray400,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: AppTheme.orange500,
                                      inactiveTrackColor: AppTheme.gray200,
                                      thumbColor: AppTheme.orange500,
                                      overlayColor: AppTheme.orange500
                                          .withOpacity(0.12),
                                      valueIndicatorColor: AppTheme.orange500,
                                      valueIndicatorTextStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    child: Slider(
                                      value: _selectedDays,
                                      min: 7,
                                      max: 90,
                                      divisions: 83,
                                      label: '$days дн.',
                                      onChanged: (v) =>
                                          setState(() => _selectedDays = v),
                                    ),
                                  ),
                                ),
                                Text(
                                  '90',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.gray400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Period summary
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.orange50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$days дн.  |  с ${_formatDate(_startDate)} по ${_formatDate(_endDate)}',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.gray800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Условия', style: AppTheme.titleMedium),
                            SizedBox(height: 12),
                            _ConditionItem(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Баланс менее 100 руб.',
                            ),
                            _ConditionItem(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Нет предыдущих обещанных платежей в этом месяце',
                            ),
                            _ConditionItem(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Аккаунт не заблокирован',
                            ),
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
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.error,
                                  ),
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
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 64,
                                color: AppTheme.success,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Обещанный платёж активирован',
                                style: AppTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Срок оплаты продлён на $days дн. (до ${_formatDate(_endDate)}). Пополните баланс вовремя.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.gray600,
                                ),
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
                            onPressed: _isSubmitting
                                ? null
                                : _activatePromisedPayment,
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
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Активировать',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray700),
            ),
          ),
        ],
      ),
    );
  }
}
