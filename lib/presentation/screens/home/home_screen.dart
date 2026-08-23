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
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppTheme.orange500,
            onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                // ─── App Bar ─────────────────────────
                SliverToBoxAdapter(
                  child: _buildAppBar(user, homeState),
                ),
                // ─── Content ──────────────────────────
                if (homeState is HomeLoading || homeState is HomeInitial)
                  const SliverFillRemaining(
                    child: LoadingSpinner(),
                  )
                else if (homeState is HomeError)
                  SliverFillRemaining(
                    child: _buildErrorState(homeState.message),
                  )
                else if (homeState is HomeLoaded)
                  SliverToBoxAdapter(
                    child: _buildContent(homeState),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
          // ─── Lock Overlay ────────────────────────
          if (homeState is HomeLoaded && homeState.isLocked)
            _buildLockOverlay(homeState),
        ],
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────

  Widget _buildAppBar(User? user, HomeState homeState) {
    final isLocked = homeState is HomeLoaded && homeState.isLocked;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Gradient avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.orange500, Color(0xFFE91E63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                user?.fullName.isNotEmpty == true
                    ? user!.fullName[0]
                    : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // PIN + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.id ?? '------',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.gray500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
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
          // Bell
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.gray600,
              size: 24,
            ),
            onPressed: () {},
          ),
          // Settings
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppTheme.gray600,
              size: 24,
            ),
            onPressed: () => context.push(Routes.settings),
          ),
          // Lock toggle
          IconButton(
            icon: Icon(
              isLocked
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              color: isLocked ? AppTheme.orange500 : AppTheme.gray400,
              size: 22,
            ),
            onPressed: () {
              ref.read(homeViewModelProvider.notifier).toggleLock();
            },
          ),
          // Logout
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: AppTheme.gray400,
              size: 22,
            ),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go(Routes.login);
            },
          ),
        ],
      ),
    );
  }

  // ─── Lock Overlay ─────────────────────────────────────────

  Widget _buildLockOverlay(HomeLoaded state) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              const Text(
                'Приложение заблокировано',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(homeViewModelProvider.notifier).toggleLock();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Разблокировать',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Dashboard Content ───────────────────────────────────

  Widget _buildContent(HomeLoaded state) {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Balance ───────────────────────
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
                Text(
                  'Баланс',
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCurrency(state.balance.amount),
                      style: AppTheme.balanceAmount.copyWith(fontSize: 48),
                    ),
                  ],
                ),
                if (state.balance.paidUntil != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Оплачено ${DateFormatter.formatPaidUntil(state.balance.paidUntil!)}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.success,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Action buttons
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
                  Text(
                    'Активные услуги',
                    style: AppTheme.titleMedium,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.gray400,
                    size: 24,
                  ),
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
            border: isPrimary
                ? null
                : Border.all(color: AppTheme.gray200),
            color: isPrimary ? AppTheme.orange500 : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : AppTheme.gray600,
                size: 20,
              ),
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
