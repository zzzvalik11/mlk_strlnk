import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

/// Unified app header used on every screen.
/// Shows user avatar, name, ID, notification bell, settings & logout.
class AppHeader extends ConsumerWidget {
  final String? title;
  final int unreadNotifications;
  final bool showBackButton;

  const AppHeader({
    super.key,
    this.title,
    this.unreadNotifications = 2,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

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
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          // Avatar
          Container(
            width: 44,
            height: 44,
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
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
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
                  unreadNotifications > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: unreadNotifications > 0 ? AppTheme.orange500 : AppTheme.gray600,
                  size: 24,
                ),
                onPressed: () => context.push(Routes.notifications),
              ),
              if (unreadNotifications > 0)
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
              ref.read(authProvider.notifier).logout();
              context.go(Routes.login);
            },
          ),
        ],
      ),
    );
  }
}
