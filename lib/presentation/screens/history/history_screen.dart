import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';
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

  Future<void> _pickDateRange(BuildContext context, HistoryNotifier notifier) async {
    final initial = notifier.customRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
      locale: const Locale('ru'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.orange500,
              onPrimary: Colors.white,
              onSurface: AppTheme.gray900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      notifier.setCustomRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyViewModelProvider);
    final notifier = ref.read(historyViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBackButton: true, title: 'История операций'),
          // ─── Period Filter ──────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: HistoryPeriod.values.map((p) {
                final isActive = notifier.period == p;
                String label = p.label;
                if (p == HistoryPeriod.custom && notifier.customRange != null) {
                  final r = notifier.customRange!;
                  label = '${DateFormatter.formatDate(r.start)} – ${DateFormatter.formatDate(r.end)}';
                }
                return ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 13)),
                  selected: isActive,
                  onSelected: p == HistoryPeriod.custom
                      ? (_) => _pickDateRange(context, notifier)
                      : (_) => notifier.setPeriod(p),
                  selectedColor: AppTheme.orange500.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isActive ? AppTheme.orange500 : AppTheme.gray600,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // ─── Content ──────────────────────
            Expanded(
              child: switch (state) {
              HistoryLoading() => const LoadingSpinner(),
              HistoryError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => notifier.refresh(),
                ),
              HistoryEmpty() => const EmptyState(
                  icon: Icons.receipt_long_rounded,
                  message: 'Нет операций',
                  subtitle: 'Нет операций за выбранный период',
                ),
              HistoryLoaded(:final transactions, :final hasMore) =>
                RefreshIndicator(
                  color: AppTheme.orange500,
                  onRefresh: () => notifier.refresh(),
                  child: ListView.builder(
                    padding: AppTheme.screenPadding.copyWith(bottom: 16),
                    itemCount: transactions.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == transactions.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: TextButton(
                              onPressed: () => notifier.loadMore(),
                              child: const Text('Загрузить ещё'),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < transactions.length - 1 ? 8 : 0),
                        child: _TransactionItem(transaction: transactions[index]),
                      );
                    },
                  ),
                ),
              HistoryInitial() => const LoadingSpinner(),
            },
          ),
        ],
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
        color: Colors.white, borderRadius: AppTheme.cardRadius, boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description, style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(_typeLabel, style: AppTheme.labelSmall.copyWith(color: _iconColor, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(DateFormatter.formatDate(transaction.date), style: AppTheme.labelSmall),
                  ],
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

  IconData get _icon => switch (transaction.type) {
    TransactionType.topUp => Icons.add_circle_outline_rounded,
    TransactionType.payment => Icons.payment_rounded,
    TransactionType.refund => Icons.undo_rounded,
    TransactionType.bonus => Icons.card_giftcard_rounded,
  };

  Color get _iconColor => switch (transaction.type) {
    TransactionType.topUp => AppTheme.success,
    TransactionType.payment => AppTheme.orange500,
    TransactionType.refund => AppTheme.info,
    TransactionType.bonus => AppTheme.warning,
  };

  String get _typeLabel => switch (transaction.type) {
    TransactionType.topUp => 'Пополнение',
    TransactionType.payment => 'Оплата',
    TransactionType.refund => 'Возврат',
    TransactionType.bonus => 'Бонус',
  };
}
