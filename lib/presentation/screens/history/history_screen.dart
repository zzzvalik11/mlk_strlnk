import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/currency_formatter.dart';
import 'package:telecom_dashboard/core/utils/date_formatter.dart';
import 'package:telecom_dashboard/core/utils/responsive.dart';
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

  Future<void> _showCustomRangePicker() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: DateTime(now.year, now.month - 1, now.day),
      end: now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      initialEntryMode: DatePickerEntryMode.calendar,
      locale: const Locale('ru'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.orange500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.gray900,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.gray900,
              elevation: 0,
            ),
          ),
          child: child!,
        );
      },
      textDirection: TextDirection.ltr,
    );

    if (picked != null) {
      ref.read(historyViewModelProvider.notifier).setCustomRange(picked);
    }
  }

  String _formatRangeLabel(DateTimeRange range) {
    final from = _shortDate(range.start);
    final to = _shortDate(range.end);
    return '$from – $to';
  }

  String _shortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyViewModelProvider);
    final notifier = ref.read(historyViewModelProvider.notifier);
    final isCustom = notifier.period == HistoryPeriod.custom;

    // Get range label for display
    final rangeLabel = (state is HistoryLoaded && state.customRange != null)
        ? _formatRangeLabel(state.customRange!)
        : (state is HistoryEmpty && state.customRange != null)
            ? _formatRangeLabel(state.customRange!)
            : null;

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      appBar: AppBar(
        backgroundColor: AppTheme.orange50,
        elevation: 0,
        foregroundColor: AppTheme.gray900,
        title: const Text('История операций'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
          child: Column(
            children: [
              // ─── Period Filter ───────
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Quick period chips
                    ...HistoryPeriod.values.where((p) => p != HistoryPeriod.custom).map((p) {
                      final isActive = !isCustom && notifier.period == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Center(
                          child: ChoiceChip(
                            label: Text(p.label),
                            selected: isActive,
                            onSelected: (_) => notifier.setPeriod(p),
                            selectedColor: AppTheme.orange500.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isActive ? AppTheme.orange500 : AppTheme.gray600,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      );
                    }),
                    // Calendar / custom range chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Center(
                        child: ActionChip(
                          avatar: Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: isCustom ? AppTheme.orange500 : AppTheme.gray500,
                          ),
                          label: Text(
                            isCustom && rangeLabel != null
                                ? rangeLabel
                                : HistoryPeriod.custom.label,
                            style: TextStyle(
                              color: isCustom ? AppTheme.orange500 : AppTheme.gray600,
                              fontWeight: isCustom ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: _showCustomRangePicker,
                          side: isCustom
                              ? BorderSide(color: AppTheme.orange500)
                              : null,
                          backgroundColor: isCustom
                              ? AppTheme.orange500.withOpacity(0.08)
                              : null,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // ─── Content ───────────
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
      ),
    );
  }
}

// ─── Transaction Item ───────────────────────────

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
