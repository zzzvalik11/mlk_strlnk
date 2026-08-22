import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/screens/history/history_screen.dart';
import 'package:telecom_dashboard/presentation/screens/home/home_screen.dart';
import 'package:telecom_dashboard/presentation/screens/login/login_screen.dart';
import 'package:telecom_dashboard/presentation/screens/news/news_detail_screen.dart';
import 'package:telecom_dashboard/presentation/screens/news/news_screen.dart';
import 'package:telecom_dashboard/presentation/screens/payment/payment_screen.dart';
import 'package:telecom_dashboard/presentation/screens/support/support_screen.dart';
import 'package:telecom_dashboard/presentation/screens/top_up/top_up_screen.dart';
import 'package:telecom_dashboard/presentation/widgets/navigation/bottom_nav_bar.dart';

// ─── Router Provider ────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isAuthenticated = authState.valueOrNull != null;
  final isLoading = authState is AsyncLoading;

  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == Routes.login;
      final isSupportRoute = state.matchedLocation == Routes.support;

      // Allow support without auth
      if (isSupportRoute) return null;

      // If not authenticated and not already on login, redirect
      if (!isAuthenticated && !isLoading && !isLoginRoute) {
        return Routes.login;
      }

      // If authenticated and on login, go home
      if (isAuthenticated && isLoginRoute) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // Determine tab index from location
          final location = state.matchedLocation;
          int idx = 0;
          if (location.startsWith(Routes.payment)) idx = 1;
          if (location.startsWith(Routes.news)) idx = 2;
          if (location.startsWith(Routes.support)) idx = 3;

          return _ShellWrapper(
            initialIndex: idx,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: Routes.payment,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PaymentScreen(),
            ),
          ),
          GoRoute(
            path: Routes.news,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NewsScreen(),
            ),
          ),
          GoRoute(
            path: Routes.support,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SupportScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.topUp,
        builder: (context, state) => const TopUpScreen(),
      ),
      GoRoute(
        path: Routes.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '${Routes.news}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NewsDetailScreen(newsId: id);
        },
      ),
    ],
  );
});

// ─── Shell Wrapper ──────────────────────────────────────────

/// Wraps shell children with a [BottomNavBar] and manages tab state.
class _ShellWrapper extends StatefulWidget {
  final Widget child;
  final int initialIndex;

  const _ShellWrapper({required this.child, required this.initialIndex});

  @override
  State<_ShellWrapper> createState() => _ShellWrapperState();
}

class _ShellWrapperState extends State<_ShellWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant _ShellWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          final routes = [
            Routes.home,
            Routes.payment,
            Routes.news,
            Routes.support,
          ];
          context.go(routes[index]);
        },
      ),
    );
  }
}
