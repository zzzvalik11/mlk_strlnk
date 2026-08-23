import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/user_remote_source.dart';
import 'package:telecom_dashboard/data/models/user_model.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';
import 'package:telecom_dashboard/domain/repositories/user_repository.dart';

/// [UserRepository] implementation backed by remote API + local cache.
/// For the test user (ПИН 039103 / пароль 123456) returns mock data
/// without any network calls. All other users hit the real server.
class UserRepositoryImpl implements UserRepository {
  static const String _mockPin = '039103';
  static const String _mockPassword = '123456';

  final UserRemoteSource _remoteSource;
  final UserLocalSource _localSource;

  UserRepositoryImpl({
    required UserRemoteSource remoteSource,
    required UserLocalSource localSource,
  })  : _remoteSource = remoteSource,
        _localSource = localSource;

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Try local cache first
      final cached = _localSource.getUser();
      if (cached != null) {
        return right(cached.toDomain());
      }

      // If user is a mock user but cache was cleared, return mock data
      if (_localSource.isMockUser()) {
        return right(_createMockUser().toDomain());
      }

      final userModel = await _remoteSource.getUserProfile();
      await _localSource.saveUser(userModel);
      return right(userModel.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> login(String pin, {String? password}) async {
    // ── Mock path: only for 039103 / 123456 ─────────────────────
    if (pin == _mockPin) {
      if (password != null && password != _mockPassword) {
        return left(const Failure.validation(message: 'Неверный пароль'));
      }
      final userModel = _createMockUser();
      await _localSource.saveToken('mock_token_039103');
      await _localSource.saveUser(userModel);
      await _localSource.setMockUser(true);
      return right(userModel.toDomain());
    }

    // ── Real server path for all other users ─────────────────────
    try {
      final result = await _remoteSource.login(
        pin: pin,
        password: password ?? pin,
      );

      // Extract token and user from the login response
      final token = result['token'] as String?;
      final userJson = result['user'] as Map<String, dynamic>;
      final userModel = UserModel.fromJson(userJson);

      // Persist session
      if (token != null) {
        await _localSource.saveToken(token);
      }
      await _localSource.saveUser(userModel);
      await _localSource.setMockUser(false);

      return right(userModel.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(User profile) async {
    try {
      final model = profile.toModel();
      await _localSource.saveUser(model);
      return right(profile);
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  // ── Mock user data ──────────────────────────────────────────────

  UserModel _createMockUser() {
    return UserModel(
      id: _mockPin,
      fullName: 'Иванов Валентин Сергеевич',
      phone: '+7 (999) 123-45-67',
      createdAt: DateTime(2024, 1, 15),
    );
  }
}
