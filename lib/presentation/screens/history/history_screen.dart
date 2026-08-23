import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/currency_formatter.dart';
import 'package:telecom_dashboard/core/utils/date_formatter.dart';
import 'package:telecom_dashboard/core/widgets/empty_state.dart';
import 'package:telecom_dashboard/core/widgets/error_state.dart';
import 'package:telecom_dashboard/core/widgets/loading_spinner.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';
import 'package:telecom_dashboard/presentation/screens/history/history_view_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyViewModelProvider.notifier).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      appBar: AppBar(
        backgroundColor: AppTheme.orange50,
        elevation: 0,
        foregroundColor: AppTheme.gray900,
        title: const Text('История операций'),
        centerTitle: true,
      ),
      body: switch (state) {
        HistoryLoading() => const LoadingSpinner(),
        HistoryError(:final message) => ErrorState(
            message: message,
            onRetry: () => ref.read(historyViewModelProvider.notifier).refresh(),
          ),
        HistoryEmpty() => const EmptyState(
            icon: Icons.receipt_long_rounded,
            message: 'Нет операций',
            subtitle: 'Здесь появится история ваших операций',
          ),
        HistoryLoaded(:final transactions) => RefreshIndicator(
            color: AppTheme.orange500,
            onRefresh: () => ref.read(historyViewModelProvider.notifier).refresh(),
            child: ListView.separated(
              padding: AppTheme.screenPadding.copyWith(bottom: 32),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _TransactionItem(transaction: transactions[index]);
              },
            ),
          ),
        HistoryInitial() => const LoadingSpinner(),
      },
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
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconBgColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _icon,
              color: _iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Description + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _typeBadgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _typeLabel,
                        style: AppTheme.labelSmall.copyWith(
                          color: _typeBadgeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDate(transaction.date),
                      style: AppTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount
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

  Color get _iconBgColor => _iconColor;

  String get _typeLabel {
    switch (transaction.type) {
      case TransactionType.topUp:
        return 'Пополнение';
      case TransactionType.payment:
        return 'Оплата';
      case TransactionType.refund:
        return 'Возврат';
      case TransactionType.bonus:
        return 'Бонус';
    }
  }

  Color get _typeBadgeColor {
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
