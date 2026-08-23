import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/currency_formatter.dart';
import 'package:telecom_dashboard/core/utils/date_formatter.dart';
import 'package:telecom_dashboard/core/widgets/empty_state.dart';
import 'package:telecom_dashboard/core/widgets/error_state.dart';
import 'package:telecom_dashboard/core/widgets/loading_spinner.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/presentation/screens/payment/payment_view_model.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentViewModelProvider.notifier).loadRecentTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentViewModelProvider);

    return RefreshIndicator(
      color: AppTheme.orange500,
      onRefresh: () => ref.read(paymentViewModelProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
            // ─── Title ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text(
                  'Оплата',
                  style: AppTheme.headlineLarge,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            // ─── Quick Action Cards ─────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _QuickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Оплата услуг',
                      color: AppTheme.orange500,
                      onTap: () => context.push(Routes.topUp),
                    ),
                    const _QuickAction(
                      icon: Icons.send_rounded,
                      label: 'Перевод',
                      color: AppTheme.info,
                    ),
                    const _QuickAction(
                      icon: Icons.smartphone_rounded,
                      label: 'Привязать карту',
                      color: AppTheme.success,
                    ),
                    const _QuickAction(
                      icon: Icons.local_offer_rounded,
                      label: 'Промокод',
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // ─── Recent Transactions ────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Последние операции',
                  style: AppTheme.titleMedium,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            switch (state) {
              PaymentLoading() => const SliverFillRemaining(child: LoadingSpinner()),
              PaymentError(:final message) => SliverFillRemaining(
                  child: ErrorState(
                    message: message,
                    onRetry: () =>
                        ref.read(paymentViewModelProvider.notifier).refresh(),
                  ),
                ),
              PaymentEmpty() => SliverFillRemaining(
                  child: const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    message: 'Нет операций',
                  ),
                ),
              PaymentLoaded(:final recentTransactions) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: index < recentTransactions.length - 1 ? 8 : 80,
                      ),
                      child: _TransactionItem(
                          transaction: recentTransactions[index]),
                    ),
                    childCount: recentTransactions.length,
                  ),
                ),
              PaymentInitial() => const SliverFillRemaining(child: LoadingSpinner()),
            },
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Card ─────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.cardRadius,
          onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label — скоро'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          child: Padding(
            padding: AppTheme.cardPaddingSmall,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Transaction Item ──────────────────────────────────────

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.type == TransactionType.topUp ||
        transaction.type == TransactionType.refund ||
        transaction.type == TransactionType.bonus;
    final signedAmount = isPositive
        ? '+${CurrencyFormatter.formatCurrency(transaction.amount)}'
        : '-${CurrencyFormatter.formatCurrency(transaction.amount)}';

    return Container(
      padding: AppTheme.cardPaddingSmall,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.formatDate(transaction.date),
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            signedAmount,
            style: AppTheme.titleMedium.copyWith(
              color: isPositive ? AppTheme.success : AppTheme.error,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (transaction.type) {
      case TransactionType.topUp:
        return Icons.add_circle_outline_rounded;
      case TransactionType.payment:
        return Icons.payment_rounded;
      case TransactionType.refund:
        return Icons.undo_rounded;
      case TransactionType.bonus:
        return Icons.card_giftcard_rounded;
    }
  }

  Color get _iconColor {
    switch (transaction.type) {
      case TransactionType.topUp:
        return AppTheme.success;
      case TransactionType.payment:
        return AppTheme.orange500;
      case TransactionType.refund:
        return AppTheme.info;
      case TransactionType.bonus:
        return AppTheme.warning;
    }
  }
}
