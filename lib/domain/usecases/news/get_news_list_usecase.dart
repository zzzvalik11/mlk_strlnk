import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/repositories/news_repository.dart';

class GetNewsListUseCase {
  final NewsRepository _repository;

  const GetNewsListUseCase(this._repository);

  Future<Either<Failure, Page<NewsItem>>> call({
    int page = 1,
    int limit = 20,
  }) {
    if (page < 1) page = 1;
    if (limit < 1) limit = 20;

    return _repository.getNewsList(page: page, limit: limit);
  }
}
