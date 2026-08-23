import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/service_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';
import 'package:telecom_dashboard/domain/repositories/service_repository.dart';

/// [ServiceRepository] implementation backed by the remote API.
class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteSource _remoteSource;

  ServiceRepositoryImpl({required ServiceRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<Either<Failure, List<Service>>> getActiveServices() async {
    try {
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
      // Fetch all services and find the one with matching id.
      // The mock API exposes services inside /account/profile only.
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
      // The mock API does not have a dedicated renew endpoint.
      // Return the existing service details as a no-op.
      final result = await getServiceDetails(id);
      return result;
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
