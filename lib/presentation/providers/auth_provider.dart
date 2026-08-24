import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/app_constants.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/datasources/remote/user_remote_source.dart';
import 'package:telecom_dashboard/data/local/storage_service.dart';
import 'package:telecom_dashboard/data/repositories/user_repository_impl.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';
import 'package:telecom_dashboard/domain/repositories/user_repository.dart';
import 'package:telecom_dashboard/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:telecom_dashboard/domain/usecases/auth/login_usecase.dart';

// ─── ApiClient Singleton ─────────────────────────────────────────

ApiClient? _apiClientSingleton;

ApiClient _createApiClient(StorageService storageService) {
  return ApiClient(storageService: storageService);
}

void resetApiClient() {
  _apiClientSingleton = null;
}

// ─── Infrastructure Providers ────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  return service;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  _apiClientSingleton ??= _createApiClient(storageService);
  return _apiClientSingleton!;
});

// ─── Data-Source Providers ────────────────────────────────────────

final userRemoteSourceProvider = Provider<UserRemoteSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRemoteSource(apiClient: apiClient);
});

final userLocalSourceProvider = Provider<UserLocalSource>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return UserLocalSource(storageService: storageService);
});

// ─── Repository Providers ────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteSource: ref.watch(userRemoteSourceProvider),
    localSource: ref.watch(userLocalSourceProvider),
  );
});

// ─── Use-Case Providers ──────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(userRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(userRepositoryProvider));
});

// ─── Auth State ──────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final LoginUseCase _loginUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UserLocalSource _localSource;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required UserLocalSource localSource,
  })  : _loginUseCase = loginUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _localSource = localSource,
        super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = _localSource.getToken();
      // Check if token exists and has not expired
      if (token != null && _localSource.isTokenValid()) {
        final cached = _localSource.getUser();
        if (cached != null) {
          state = AsyncValue.data(cached.toDomain());
          return;
        }
      }
      // Token expired or missing — clear session
      if (token != null) {
        await _localSource.clearSession();
      }
      state = const AsyncValue.data(null);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> checkAuth() => _checkAuth();

  /// Full login with PIN + password. Sets token expiry to 365 days.
  Future<void> login({
    required String pin,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _loginUseCase.call(pin: pin, password: password);
      await result.fold(
        (failure) async {
          state = AsyncValue.error(
            _mapFailureToException(failure),
            StackTrace.current,
          );
        },
        (user) async {
          // Set token expiry to 365 days from now
          final expiry = DateTime.now().add(AppConstants.tokenValidity);
          await _localSource.saveTokenExpiry(expiry);
          state = AsyncValue.data(user);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Quick re-login with PIN only (for returning users).
  /// Validates PIN matches cached user and token is still valid.
  Future<void> authenticateWithPin({required String pin}) async {
    state = const AsyncValue.loading();
    try {
      if (!_localSource.isTokenValid()) {
        await _localSource.clearSession();
        state = const AsyncValue.data(null);
        throw Exception('Сессия истекла. Войдите заново.');
      }
      final cached = _localSource.getUser();
      if (cached == null) {
        throw Exception('Нет сохранённых данных. Войдите заново.');
      }
      if (cached.id != pin) {
        throw Exception('Неверный ПИН-код');
      }
      state = AsyncValue.data(cached.toDomain());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Biometric re-login. Token validity is checked; biometric prompt
  /// is handled at UI level via local_auth package.
  Future<void> authenticateWithBiometric() async {
    state = const AsyncValue.loading();
    try {
      if (!_localSource.isTokenValid()) {
        await _localSource.clearSession();
        state = const AsyncValue.data(null);
        throw Exception('Сессия истекла. Войдите заново.');
      }
      final cached = _localSource.getUser();
      if (cached == null) {
        throw Exception('Нет сохранённых данных. Войдите заново.');
      }
      state = AsyncValue.data(cached.toDomain());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _localSource.clearSession();
    resetApiClient();
    state = const AsyncValue.data(null);
  }
}

Exception _mapFailureToException(Failure failure) {
  return failure.when(
    network: (m) => Exception(m),
    server: (_, m) => Exception(m),
    validation: (m) => Exception(m),
    cache: (m) => Exception(m),
    unknown: (m) => Exception(m),
  );
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
    localSource: ref.watch(userLocalSourceProvider),
  );
});
