import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

/// Bridge between Riverpod auth state and GoRouter's refreshListenable.
/// Safe to use outside Riverpod widget tree — all reads are wrapped
/// in try-catch so platform plugin errors (e.g. on web) don't propagate.
class AuthChangeNotifier extends ChangeNotifier {
  final ProviderContainer _container;

  AuthChangeNotifier(this._container) {
    print('[ACN] Constructor start');
    try {
      print('[ACN] Calling container.listen(authProvider)');
      _container.listen<AsyncValue>(authProvider, (_, next) {
        print('[ACN] authProvider state changed: ${next.runtimeType}');
        notifyListeners();
      });
      print('[ACN] listen OK');
    } catch (e, st) {
      print('[ACN] listen EXCEPTION: $e');
      print('[ACN] listen STACK: $st');
    }
  }

  bool get isAuthenticated {
    try {
      return _container.read(authProvider).valueOrNull != null;
    } catch (_) {
      return false;
    }
  }

  bool get isLoading {
    try {
      return _container.read(authProvider) is AsyncLoading;
    } catch (_) {
      return false;
    }
  }
}
