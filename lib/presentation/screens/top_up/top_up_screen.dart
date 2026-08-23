import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
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

    // Listen for success.
    ref.listen<TopUpState>(topUpViewModelProvider, (prev, next) {
      if (next.result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Баланс пополнён: ${CurrencyFormatter.formatCurrency(next.result!.amount)}',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Invalidate balance so home screen gets fresh data.
        ref.invalidate(balanceProvider);
        context.pop(next.result);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      appBar: AppBar(
        backgroundColor: AppTheme.orange50,
        elevation: 0,
        foregroundColor: AppTheme.gray900,
        title: const Text('Пополнить баланс'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.screenPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
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
                  onPressed: topUpState.isSubmitting
                      ? null
                      : () {
                          ref.read(topUpViewModelProvider.notifier).submitTopUp();
                        },
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
                      : const Text(
                          'Пополнить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            '${CurrencyFormatter.formatCurrencyCustom(amount, decimalDigits: 0).replaceAll(' ₽', '')} ₽',
            style: AppTheme.titleMedium.copyWith(
              color: isSelected ? Colors.white : AppTheme.gray900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
