import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
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
import 'package:telecom_dashboard/presentation/screens/history/history_screen.dart';
import 'package:telecom_dashboard/presentation/widgets/navigation/bottom_nav_bar.dart';

// ─── Router Provider ────────────────────────────────────────

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
    initialLocation: Routes.login,
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

      debugPrint('🔵 REDIRECT: loc=$loc auth=$isAuthenticated isLoading=$isLoading');

      // Public routes (no auth required)
      if (isSupportRoute || isQuickLoginRoute || isAuthMethodRoute) return null;

      // Not authenticated and not loading → login
      if (!isAuthenticated && !isLoading && !isLoginRoute) {
        debugPrint('🔵 REDIRECT → login');
        return Routes.login;
      }

      // Authenticated and on login → main
      if (isAuthenticated && isLoginRoute) {
        debugPrint('🔵 REDIRECT → home (user authenticated)');
        return Routes.home;
      }

      return null;
    },
    routes: [
      // ─── Main screen with tabs (NO ShellRoute) ───
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: Routes.payment,
        builder: (context, state) => const MainScreen(initialTab: 1),
      ),
      GoRoute(
        path: Routes.news,
        builder: (context, state) => const MainScreen(initialTab: 2),
      ),
      GoRoute(
        path: Routes.support,
        builder: (context, state) => const MainScreen(initialTab: 3),
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

// ─── Main Screen with Tab Navigation ─────────────────────

class MainScreen extends StatefulWidget {
  final int initialTab;

  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    debugPrint('🟢 MainScreen.build() tab=$_currentTab');

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentTab,
        screenWidth: screenWidth,
        onTap: (index) {
          setState(() => _currentTab = index);
        },
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return const HomeScreen();
      case 1:
        return const PaymentScreen();
      case 2:
        return const NewsScreen();
      case 3:
        return const SupportScreen();
      default:
        return const HomeScreen();
    }
  }
}
