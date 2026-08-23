import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/providers/balance_provider.dart';
import 'package:telecom_dashboard/presentation/providers/services_provider.dart';

// ─── Home State (freezed-style union) ───────────────────────────

sealed class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final User user;
  final Balance balance;
  final List<Service> services;

  const HomeLoaded({
    required this.user,
    required this.balance,
    required this.services,
  });
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}

class HomeEmpty extends HomeState {
  const HomeEmpty();
}

// ─── Home Notifier ───────────────────────────────────────────────

class HomeNotifier extends StateNotifier<HomeState> {
  final Ref _ref;

  HomeNotifier(this._ref) : super(const HomeInitial());

  Future<void> loadDashboard() async {
    state = const HomeLoading();

    try {
      // Load user
      final authState = _ref.read(authProvider);
      final user = authState.valueOrNull;
      if (user == null) {
        state = const HomeError('Не авторизован');
        return;
      }

      // Load balance and services in parallel
      final balanceResult = await _ref.read(balanceProvider.future);
      final servicesResult = await _ref.read(activeServicesProvider.future);

      if (servicesResult.isEmpty) {
        state = HomeLoaded(
          user: user,
          balance: balanceResult,
          services: const [],
        );
      } else {
        state = HomeLoaded(
          user: user,
          balance: balanceResult,
          services: servicesResult,
        );
      }
    } catch (e) {
      state = HomeError(e.toString());
    }
  }

  /// Force-refresh all dashboard data.
  Future<void> refresh() async {
    // Invalidate the auto-dispose providers so they re-fetch.
    _ref.invalidate(balanceProvider);
    _ref.invalidate(activeServicesProvider);
    await loadDashboard();
  }
}

final homeViewModelProvider =
    StateNotifierProvider.autoDispose<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref);
});
