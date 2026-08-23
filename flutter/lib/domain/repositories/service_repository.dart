import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';

abstract class ServiceRepository {
  Future<Either<Failure, List<Service>>> getActiveServices();
  Future<Either<Failure, Service>> getServiceDetails(String id);
  Future<Either<Failure, Service>> renewService(String id);
}
