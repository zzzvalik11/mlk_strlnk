import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';

abstract class ServiceRepository {
  Future<Either<Failure, List<Service>>> getActiveServices({int accountId = 1});
  Future<Either<Failure, Service>> getServiceDetails(String id, {int accountId = 1});
  Future<Either<Failure, Service>> renewService(String id, {int accountId = 1});
}
