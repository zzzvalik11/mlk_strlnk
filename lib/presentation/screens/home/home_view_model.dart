import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
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
  final bool isLocked;

  const HomeLoaded({
    required this.user,
    required this.balance,
    required this.services,
    this.isLocked = false,
  });

  HomeLoaded copyWith({bool? isLocked}) {
    return HomeLoaded(
      user: user,
      balance: balance,
      services: services,
      isLocked: isLocked ?? this.isLocked,
    );
  }
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
    debugPrint('🔴 HomeNotifier.loadDashboard() START');

    try {
      // Load user
      final authState = _ref.read(authProvider);
      final user = authState.valueOrNull;
      if (user == null) {
        debugPrint('🔴 HomeNotifier: user is null!');
        state = const HomeError('Не авторизован');
        return;
      }
      debugPrint('🔴 HomeNotifier: user=${user.fullName}, loading balance...');

      // Load balance and services in parallel
      final balanceResult = await _ref.read(balanceProvider.future);
      debugPrint('🔴 HomeNotifier: balance loaded=${balanceResult.amount}');
      final servicesResult = await _ref.read(activeServicesProvider.future);
      debugPrint('🔴 HomeNotifier: services loaded, count=${servicesResult.length}');

      final localSource = _ref.read(userLocalSourceProvider);
      final locked = localSource.isLocked();

      if (servicesResult.isEmpty) {
        state = HomeLoaded(
          user: user,
          balance: balanceResult,
          services: const [],
          isLocked: locked,
        );
      } else {
        state = HomeLoaded(
          user: user,
          balance: balanceResult,
          services: servicesResult,
          isLocked: locked,
        );
      }
    } catch (e) {
      debugPrint('🔴 HomeNotifier ERROR: $e');
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

  /// Toggle app lock state.
  Future<void> toggleLock() async {
    if (state is! HomeLoaded) return;
    final current = (state as HomeLoaded).isLocked;
    final newLocked = !current;
    final localSource = _ref.read(userLocalSourceProvider);
    await localSource.setLocked(newLocked);
    state = (state as HomeLoaded).copyWith(isLocked: newLocked);
  }
}

final homeViewModelProvider =
    StateNotifierProvider.autoDispose<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref);
});
