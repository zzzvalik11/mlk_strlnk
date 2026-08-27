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
  print('[PROV] storageServiceProvider (overridden)');
  final service = StorageService();
  return service;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  print('[PROV] apiClientProvider -> watching storageServiceProvider');
  final storageService = ref.watch(storageServiceProvider);
  print('[PROV] apiClientProvider -> creating ApiClient');
  _apiClientSingleton ??= _createApiClient(storageService);
  return _apiClientSingleton!;
});

// ─── Data-Source Providers ────────────────────────────────────────

final userRemoteSourceProvider = Provider<UserRemoteSource>((ref) {
  print('[PROV] userRemoteSourceProvider -> watching apiClientProvider');
  final apiClient = ref.watch(apiClientProvider);
  print('[PROV] userRemoteSourceProvider -> created');
  return UserRemoteSource(apiClient: apiClient);
});

final userLocalSourceProvider = Provider<UserLocalSource>((ref) {
  print('[PROV] userLocalSourceProvider -> watching storageServiceProvider');
  final storageService = ref.watch(storageServiceProvider);
  print('[PROV] userLocalSourceProvider -> created');
  return UserLocalSource(storageService: storageService);
});

// ─── Repository Providers ────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  print('[PROV] userRepositoryProvider -> watching remote+local sources');
  return UserRepositoryImpl(
    remoteSource: ref.watch(userRemoteSourceProvider),
    localSource: ref.watch(userLocalSourceProvider),
  );
});

// ─── Use-Case Providers ──────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  print('[PROV] loginUseCaseProvider -> watching userRepositoryProvider');
  return LoginUseCase(ref.watch(userRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  print('[PROV] getCurrentUserUseCaseProvider -> watching userRepositoryProvider');
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
    print('[AUTH_N] Constructor OK, calling _checkAuth');
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    print('[AUTH_N] _checkAuth start');
    try {
      print('[AUTH_N] calling getToken()');
      final token = _localSource.getToken();
      print('[AUTH_N] token=$token');
      if (token != null && _localSource.isTokenValid()) {
        final cached = _localSource.getUser();
        if (cached != null) {
          state = AsyncValue.data(cached.toDomain());
          return;
        }
      }
      if (token != null) {
        await _localSource.clearSession();
      }
      print('[AUTH_N] _checkAuth -> data(null)');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      print('[AUTH_N] _checkAuth EXCEPTION: $e');
      print('[AUTH_N] _checkAuth STACK: $st');
      state = const AsyncValue.data(null);
    }
  }

  Future<void> checkAuth() => _checkAuth();

  /// Full login with PIN + password. Sets token expiry to 365 days.
  Future<void> login({
    required String pin,
    required String password,
  }) async {
    print('[AUTH_N] login(pin=$pin, password=$password)');
    state = const AsyncValue.loading();
    try {
      final result = await _loginUseCase.call(pin: pin, password: password);
      print('[AUTH_N] login usecase returned isRight=${result.isRight()}');
      result.fold(
        (failure) {
          state = AsyncValue.error(
            _mapFailureToException(failure),
            StackTrace.current,
          );
        },
        (user) {
          _localSource.saveTokenExpiry(
            DateTime.now().add(AppConstants.tokenValidity),
          );
          state = AsyncValue.data(user);
        },
      );
    } catch (e, st) {
      print('[AUTH_N] login EXCEPTION: $e');
      print('[AUTH_N] login STACK: $st');
      state = AsyncValue.error(e, st);
    }
  }

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
  print('[PROV] authProvider -> step 1: loginUseCaseProvider');
  final a = ref.watch(loginUseCaseProvider);
  print('[PROV] authProvider -> step 2: getCurrentUserUseCaseProvider');
  final b = ref.watch(getCurrentUserUseCaseProvider);
  print('[PROV] authProvider -> step 3: userLocalSourceProvider');
  final c = ref.watch(userLocalSourceProvider);
  print('[PROV] authProvider -> step 4: creating AuthNotifier');
  return AuthNotifier(
    loginUseCase: a,
    getCurrentUserUseCase: b,
    localSource: c,
  );
});
