import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/screens/history/history_screen.dart';
import 'package:telecom_dashboard/presentation/screens/home/home_screen.dart';
import 'package:telecom_dashboard/presentation/screens/login/auth_method_selection_screen.dart';
import 'package:telecom_dashboard/presentation/screens/login/login_screen.dart';
import 'package:telecom_dashboard/presentation/screens/login/quick_login_screen.dart';
import 'package:telecom_dashboard/presentation/screens/news/news_detail_screen.dart';
import 'package:telecom_dashboard/presentation/screens/news/news_screen.dart';
import 'package:telecom_dashboard/presentation/screens/notifications/notifications_screen.dart';
import 'package:telecom_dashboard/presentation/screens/payment/payment_screen.dart';
import 'package:telecom_dashboard/presentation/screens/services/services_screen.dart';
import 'package:telecom_dashboard/presentation/screens/settings/settings_screen.dart';
import 'package:telecom_dashboard/presentation/screens/support/support_screen.dart';
import 'package:telecom_dashboard/presentation/screens/top_up/top_up_screen.dart';
import 'package:telecom_dashboard/presentation/widgets/navigation/bottom_nav_bar.dart';

// ─── Router Provider ────────────────────────────────────────

/// Notifies GoRouter when auth state changes, without recreating
/// the router instance. This prevents the entire widget tree from
/// being torn down and rebuilt on every auth transition.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.valueOrNull != null;
      final isLoading = authState is AsyncLoading;

      final loc = state.matchedLocation;
      final isLoginRoute = loc == Routes.login;
      final isSupportRoute = loc == Routes.support;
      final isQuickLoginRoute = loc == Routes.quickLogin;
      final isAuthMethodRoute = loc == Routes.authMethodSelection;

      // Public routes (no auth required)
      if (isSupportRoute || isQuickLoginRoute || isAuthMethodRoute) return null;

      // Not authenticated → login
      if (!isAuthenticated && !isLoading && !isLoginRoute) {
        return Routes.login;
      }

      // Authenticated and on login → home
      if (isAuthenticated && isLoginRoute) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
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
      // Auth routes
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.quickLogin,
        builder: (context, state) => const QuickLoginScreen(),
      ),
      GoRoute(
        path: Routes.authMethodSelection,
        builder: (context, state) => const AuthMethodSelectionScreen(),
      ),
      // App routes
      GoRoute(
        path: Routes.topUp,
        builder: (context, state) => const TopUpScreen(),
      ),
      GoRoute(
        path: Routes.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.services,
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationsScreen(),
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

class _ShellWrapper extends StatefulWidget {
  final Widget child;
  final int initialIndex;

  const _ShellWrapper({super.key, required this.child, required this.initialIndex});

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
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: Container(
        color: Colors.red,
        child: Center(
          child: Text(
            'SHELL BODY TEST',
            style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      // body: widget.child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        screenWidth: screenWidth,
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
