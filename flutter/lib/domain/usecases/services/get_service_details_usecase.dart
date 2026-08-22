import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';
import 'package:telecom_dashboard/domain/repositories/service_repository.dart';

class GetServiceDetailsUseCase {
  final ServiceRepository _repository;

  const GetServiceDetailsUseCase(this._repository);

  Future<Either<Failure, Service>> call({required String id}) {
    if (id.isEmpty) {
      return Future.value(
        left(Failure.validation(message: 'ID услуги не может быть пустым')),
      );
    }

    return _repository.getServiceDetails(id);
  }
}
