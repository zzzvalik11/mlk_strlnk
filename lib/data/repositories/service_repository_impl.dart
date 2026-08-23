import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/service_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';
import 'package:telecom_dashboard/domain/repositories/service_repository.dart';

/// [ServiceRepository] implementation backed by the remote API.
/// Returns mock data when the current user is the test user (039103).
class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteSource _remoteSource;
  final UserLocalSource _localSource;

  ServiceRepositoryImpl({
    required ServiceRemoteSource remoteSource,
    required UserLocalSource localSource,
  })  : _remoteSource = remoteSource,
        _localSource = localSource;

  @override
  Future<Either<Failure, List<Service>>> getActiveServices() async {
    try {
      // Mock data for test user — no network calls
      if (_localSource.isMockUser()) {
        return right(_createMockServices());
      }

      final models = await _remoteSource.getActiveServices();
      return right(models.map((m) => m.toDomain()).toList());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Service>> getServiceDetails(String id) async {
    try {
      if (_localSource.isMockUser()) {
        final all = _createMockServices();
        final match = all.where((s) => s.id == id).firstOrNull;
        if (match == null) {
          return left(const Failure.server(statusCode: 404, message: 'Услуга не найдена'));
        }
        return right(match);
      }

      final models = await _remoteSource.getActiveServices();
      final match = models.where((m) => m.id == id).firstOrNull;
      if (match == null) {
        return left(
          Failure.server(statusCode: 404, message: 'Услуга не найдена'),
        );
      }
      return right(match.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Service>> renewService(String id) async {
    try {
      if (_localSource.isMockUser()) {
        final result = await getServiceDetails(id);
        return result;
      }

      final result = await getServiceDetails(id);
      return result;
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  // ── Mock services data ────────────────────────────────────────

  List<Service> _createMockServices() {
    return [
      Service(
        id: '1',
        name: 'Интернет 100 Мбит/с',
        category: 'Интернет',
        cost: 590.0,
        status: ServiceStatus.active,
        billingCycle: 'Ежемесячно',
      ),
      Service(
        id: '2',
        name: 'ТВ-пакет «Базовый»',
        category: 'ТВ',
        cost: 250.0,
        status: ServiceStatus.active,
        billingCycle: 'Ежемесячно',
      ),
      Service(
        id: '3',
        name: 'Защита от спама',
        category: 'Безопасность',
        cost: 50.0,
        status: ServiceStatus.active,
        billingCycle: 'Ежемесячно',
      ),
    ];
  }
}
