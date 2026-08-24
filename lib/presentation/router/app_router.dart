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
    _ref.listen(authProvider, (_, next) {
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
      final isPublicRoute = loc == Routes.support ||
          loc == Routes.quickLogin ||
          loc == Routes.authMethodSelection;

      // Public routes — always accessible
      if (isPublicRoute) return null;

      // Not authenticated and not loading → redirect to login
      if (!isAuthenticated && !isLoading && !isLoginRoute) {
        return Routes.login;
      }

      // Authenticated and on login → redirect to home
      if (isAuthenticated && isLoginRoute) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      // ─── Main screen ───
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const MainScreen(),
      ),
      // ─── Auth routes ───
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
      // ─── Public route (from login screen link) ───
      GoRoute(
        path: Routes.support,
        builder: (context, state) => Scaffold(
          backgroundColor: AppTheme.orange50,
          appBar: AppBar(
            backgroundColor: AppTheme.orange50,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go(Routes.login),
            ),
            title: const Text('Поддержка'),
          ),
          body: const SupportScreen(),
        ),
      ),
      // ─── Detail routes ───
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
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentTab,
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
