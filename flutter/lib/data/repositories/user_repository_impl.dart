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
class UserRepositoryImpl implements UserRepository {
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
  Future<Either<Failure, User>> login(String pin) async {
    try {
      final result = await _remoteSource.login(pin: pin, password: pin);

      // Extract token and user from the login response
      final token = result['token'] as String?;
      final userJson = result['user'] as Map<String, dynamic>;
      final userModel = UserModel.fromJson(userJson);

      // Persist session
      if (token != null) {
        await _localSource.saveToken(token);
      }
      await _localSource.saveUser(userModel);

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
      // The current mock API does not have a profile update endpoint.
      // Fallback: save locally and return the updated profile.
      final model = UserModel.fromDomain(profile);
      await _localSource.saveUser(model);
      return right(profile);
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
