import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';
import 'package:telecom_dashboard/domain/repositories/news_repository.dart';

class GetNewsByIdUseCase {
  final NewsRepository _repository;

  const GetNewsByIdUseCase(this._repository);

  Future<Either<Failure, NewsItem>> call({required String id}) {
    if (id.isEmpty) {
      return Future.value(
        left(Failure.validation(message: 'ID новости не может быть пустым')),
      );
    }

    return _repository.getNewsById(id);
  }
}
