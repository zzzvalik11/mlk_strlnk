import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';
import 'package:telecom_dashboard/domain/repositories/service_repository.dart';

class GetActiveServicesUseCase {
  final ServiceRepository _repository;

  const GetActiveServicesUseCase(this._repository);

  Future<Either<Failure, List<Service>>> call() {
    return _repository.getActiveServices();
  }
}
