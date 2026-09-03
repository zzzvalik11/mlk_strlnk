import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';
import 'package:telecom_dashboard/main.dart' show appContainer;
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/providers/notifications_provider.dart';

/// Unified app header used on every screen.
/// Shows user avatar, name, ID, notification bell, settings & logout.
class AppHeader extends ConsumerWidget {
  final String? title;
  final bool showBackButton;

  const AppHeader({
    super.key,
    this.title,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read auth state directly from container (bypasses WidgetRef on web)
    User? user;
    try {
      user = appContainer.read(authProvider).valueOrNull;
    } catch (_) {
      user = null;
    }
    final unreadCount = ref.read(unreadNotificationsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          if (showBackButton)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: AppTheme.gray700,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(Routes.home);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          // Logo
          Image.asset(
            'assets/images/logo.png',
            width: 40,
            height: 40,
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
                if (title != null)
                  Text(title!, style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)
                else
                  Text(user?.fullName ?? '', style: AppTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Bell
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  unreadCount > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: unreadCount > 0 ? AppTheme.orange500 : AppTheme.gray600,
                  size: 24,
                ),
                onPressed: () => context.push(Routes.notifications),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.gray600, size: 24),
            onPressed: () => context.push(Routes.settings),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.gray400, size: 22),
            onPressed: () {
              try { appContainer.read(authProvider.notifier).logout(); } catch (_) {}
              context.go(Routes.login);
            },
          ),
        ],
      ),
    );
  }
}
