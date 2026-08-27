import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/currency_formatter.dart';
import 'package:telecom_dashboard/core/utils/date_formatter.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';
import 'package:telecom_dashboard/core/widgets/loading_spinner.dart';
import 'package:telecom_dashboard/core/widgets/service_card.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/main.dart' show appContainer;
import 'package:telecom_dashboard/presentation/screens/home/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    // Safe read via global container (bypasses WidgetRef on web)
    final user = () {
      try { return appContainer.read(authProvider).valueOrNull; } catch (_) { return null; }
    }();

    return RefreshIndicator(
      color: AppTheme.orange500,
      onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: AppHeader(title: user?.fullName)),
          if (homeState is HomeLoading || homeState is HomeInitial)
            const SliverFillRemaining(child: LoadingSpinner())
          else if (homeState is HomeError)
            SliverFillRemaining(child: _buildErrorState(homeState.message))
          else if (homeState is HomeLoaded)
            SliverToBoxAdapter(child: _buildContent(homeState)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // ─── Dashboard Content ───────────────────────────────────

  Widget _buildContent(HomeLoaded state) {
    final isFrozen = state.isLocked;
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Balance Card ───────────────
          Container(
            padding: AppTheme.cardPadding,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: AppTheme.cardRadius, boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Баланс', style: AppTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatCurrency(state.balance.amount),
                  style: AppTheme.balanceAmount.copyWith(fontSize: 48),
                ),
                if (state.balance.paidUntil != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Оплачено ${DateFormatter.formatPaidUntil(state.balance.paidUntil!)}',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.success),
                  ),
                ],
                if (isFrozen)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 14, color: AppTheme.warning),
                        const SizedBox(width: 4),
                        Text('Тариф заморожен', style: AppTheme.bodySmall.copyWith(color: AppTheme.warning, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'ПОПОЛНИТЬ',
                        icon: Icons.add_circle_outline_rounded,
                        isPrimary: true,
                        onTap: () => context.push(Routes.topUp),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'ИСТОРИЯ',
                        icon: Icons.history_rounded,
                        isPrimary: false,
                        onTap: () => context.push(Routes.history),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ─── Active Services ──────────────
          if (state.services.isNotEmpty) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push(Routes.services),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text('Активные услуги', style: AppTheme.titleMedium),
                  const Spacer(),
                  // Freeze/unfreeze lock
                  IconButton(
                    icon: Icon(
                      isFrozen ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: isFrozen ? AppTheme.orange500 : AppTheme.gray400,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: () => _showFreezeDialog(isFrozen),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.gray400, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...state.services.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ServiceCard(service: s),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Freeze / Unfreeze Dialog ─────────────────────────────

  void _showFreezeDialog(bool isFrozen) {
    if (isFrozen) {
      _showUnfreezeDialog();
    } else {
      _showFreezePeriodPicker();
    }
  }

  void _showUnfreezeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Отменить заморозку'),
        content: const Text('Вы уверены, что хотите отменить заморозку тарифного плана? Услуги будут возобновлены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(homeViewModelProvider.notifier).toggleLock();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange500, foregroundColor: Colors.white, elevation: 0,
            ),
            child: const Text('Отменить заморозку'),
          ),
        ],
      ),
    );
  }

  void _showFreezePeriodPicker() {
    int selectedDays = 7;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Заморозка тарифа'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите период заморозки. Заморозка начнётся с завтрашнего дня. Во время заморозки услуги будут приостановлены.',
                style: TextStyle(fontSize: 14, color: AppTheme.gray700),
              ),
              const SizedBox(height: 20),
              const Text('Период:', style: AppTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [7, 14, 30, 60, 90].map((days) {
                  final isSelected = selectedDays == days;
                  return ChoiceChip(
                    label: Text('$days дн.'),
                    selected: isSelected,
                    onSelected: (_) => setDialogState(() => selectedDays = days),
                    selectedColor: AppTheme.orange500.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.orange500 : AppTheme.gray700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Заморозка до: ${_formatDate(DateTime.now().add(Duration(days: selectedDays + 1)))}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(homeViewModelProvider.notifier).toggleLock();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange500, foregroundColor: Colors.white, elevation: 0,
              ),
              child: const Text('Заморозить'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(message, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(homeViewModelProvider.notifier).refresh(),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ─────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
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
          height: 48,
          decoration: BoxDecoration(
            borderRadius: AppTheme.buttonRadius,
            border: isPrimary ? null : Border.all(color: AppTheme.gray200),
            color: isPrimary ? AppTheme.orange500 : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isPrimary ? Colors.white : AppTheme.gray600, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: isPrimary ? Colors.white : AppTheme.gray700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
