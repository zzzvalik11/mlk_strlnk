import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';
import 'package:telecom_dashboard/core/utils/currency_formatter.dart';
import 'package:telecom_dashboard/presentation/providers/balance_provider.dart';
import 'package:telecom_dashboard/presentation/screens/top_up/top_up_view_model.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final _customAmountController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topUpState = ref.watch(topUpViewModelProvider);

    ref.listen<TopUpState>(topUpViewModelProvider, (prev, next) {
      if (next.result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Баланс пополнён',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(balanceProvider);
        context.pop(next.result);
      }
    });

    final effectiveAmount = ref.read(topUpViewModelProvider.notifier).effectiveAmount;

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBackButton: true, title: 'Пополнить баланс'),
            Expanded(
              child: SingleChildScrollView(
        padding: AppTheme.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Quick Amounts Grid ──────────────
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: TopUpNotifier.quickAmounts.map((amount) {
                final isSelected = topUpState.selectedAmount == amount;
                return _QuickAmountButton(
                  amount: amount,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(topUpViewModelProvider.notifier).selectQuickAmount(amount);
                    _customAmountController.clear();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // ─── Custom Amount ───────────────────
            Text(
              'Или введите свою сумму',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                ref.read(topUpViewModelProvider.notifier).updateCustomAmount(value);
              },
              decoration: InputDecoration(
                hintText: '0,00',
                suffixText: '₽',
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: BorderSide(color: AppTheme.orange500, width: 2),
                ),
              ),
            ),
            // ─── Total Display ───────────────────
            if (effectiveAmount != null && effectiveAmount > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.cardRadius,
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Итого:', style: AppTheme.titleMedium.copyWith(color: AppTheme.gray600)),
                    Text(
                      CurrencyFormatter.formatCurrency(effectiveAmount),
                      style: AppTheme.headlineSmall.copyWith(
                        color: AppTheme.gray900,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ─── Error ───────────────────────────
            if (topUpState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  topUpState.error!,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            // ─── Submit Button ───────────────────
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (effectiveAmount == null || effectiveAmount <= 0 || topUpState.isSubmitting)
                    ? null
                    : () => _showPaymentMethods(context, effectiveAmount!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.orange200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: topUpState.isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Пополнить${effectiveAmount != null && effectiveAmount > 0 ? '' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethods(BuildContext context, double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PaymentMethodSheet(amount: amount),
    );
  }
}

// ─── Quick Amount Button ────────────────────────────────────

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = _formatAmount(amount);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.buttonRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.buttonRadius,
            color: isSelected ? AppTheme.orange500 : Colors.white,
            border: Border.all(
              color: isSelected ? AppTheme.orange500 : AppTheme.gray200,
            ),
            boxShadow: isSelected ? null : AppTheme.cardShadow,
          ),
          alignment: Alignment.center,
          child: Text(
            '$label ₽',
            style: AppTheme.titleMedium.copyWith(
              color: isSelected ? Colors.white : AppTheme.gray900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
}

// ─── Payment Method Bottom Sheet ────────────────────────────

class _PaymentMethodSheet extends ConsumerWidget {
  final double amount;

  const _PaymentMethodSheet({required this.amount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            Text(
              'Сумма пополнения',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.formatCurrency(amount),
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Methods
            _PaymentMethodTile(
              icon: Icons.credit_card_rounded,
              title: 'Банковская карта',
              subtitle: 'Visa, Mastercard, МИР',
              onTap: () {
                Navigator.pop(context);
                ref.read(topUpViewModelProvider.notifier).submitTopUp();
              },
            ),
            const SizedBox(height: 8),
            _PaymentMethodTile(
              icon: Icons.account_balance_rounded,
              title: 'СБП',
              subtitle: 'Система быстрых платежей',
              onTap: () {
                Navigator.pop(context);
                ref.read(topUpViewModelProvider.notifier).submitTopUp();
              },
            ),
            const SizedBox(height: 8),
            _PaymentMethodTile(
              icon: Icons.schedule_rounded,
              title: 'Обещанный платёж',
              subtitle: 'Оплата из средств следующего периода',
              onTap: () {
                Navigator.pop(context);
                ref.read(topUpViewModelProvider.notifier).submitTopUp();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentMethodTile({
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
        borderRadius: AppTheme.cardRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppTheme.cardRadius,
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.orange500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.orange500, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.gray400),
            ],
          ),
        ),
      ),
    );
  }
}
