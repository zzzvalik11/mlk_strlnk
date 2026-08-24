import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/currency_formatter.dart';
import 'package:telecom_dashboard/core/utils/date_formatter.dart';
import 'package:telecom_dashboard/core/widgets/loading_spinner.dart';
import 'package:telecom_dashboard/core/widgets/service_card.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/screens/home/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _unreadNotifications = 2;
  bool _dashboardLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryLoadDashboard();
    });
  }

  void _tryLoadDashboard() {
    final authState = ref.read(authProvider);
    final user = authState.valueOrNull;
    debugPrint('🟡 _tryLoadDashboard: user=${user != null} loaded=$_dashboardLoaded');
    if (user != null && !_dashboardLoaded) {
      ref.read(homeViewModelProvider.notifier).loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    debugPrint('🟡 HomeScreen.build(): state=${homeState.runtimeType} user=${user?.fullName}');

    // Re-trigger load when user becomes available
    ref.listen(authProvider, (prev, next) {
      if (next.valueOrNull != null && !_dashboardLoaded) {
        _tryLoadDashboard();
      }
    });

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── AppBar (always visible) ───
          _buildAppBar(user),
          // ─── State Content ───
          if (homeState is HomeLoaded)
            _buildContent(homeState)
          else if (homeState is HomeError)
            _buildErrorState(homeState.message)
          else
            _buildLoadingState(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────

  Widget _buildAppBar(User? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.orange500, Color(0xFFE91E63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'S',
                style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.id ?? '------',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.gray500, fontWeight: FontWeight.w600, letterSpacing: 1.5,
                  ),
                ),
                Text(
                  user?.fullName ?? '',
                  style: AppTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _unreadNotifications > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: _unreadNotifications > 0 ? AppTheme.orange500 : AppTheme.gray600,
                  size: 24,
                ),
                onPressed: () => context.push(Routes.notifications),
              ),
              if (_unreadNotifications > 0)
                const Positioned(
                  right: 8, top: 8,
                  child: SizedBox(
                    width: 10, height: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.gray600, size: 24),
            onPressed: () => context.push(Routes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.gray400, size: 22),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go(Routes.login);
            },
          ),
        ],
      ),
    );
  }

  // ─── Loading State ───────────────────────────────

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 400,
      child: Center(child: LoadingSpinner()),
    );
  }

  // ─── Dashboard Content ───────────────────────────

  Widget _buildContent(HomeLoaded state) {
    _dashboardLoaded = true;
    final isFrozen = state.isLocked;
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Balance Card ───────────
          Container(
            padding: AppTheme.cardPadding,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: AppTheme.cardRadius, boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Баланс', style: AppTheme.bodySmall),
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
                        const Icon(Icons.lock_rounded, size: 14, color: AppTheme.warning),
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
          // ─── Active Services ──────────
          if (state.services.isNotEmpty) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push(Routes.services),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  const Text('Активные услуги', style: AppTheme.titleMedium),
                  const Spacer(),
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

  // ─── Freeze / Unfreeze Dialog ─────────────────────

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
    return SizedBox(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(message, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _dashboardLoaded = false;
                  ref.read(homeViewModelProvider.notifier).refresh();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
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
