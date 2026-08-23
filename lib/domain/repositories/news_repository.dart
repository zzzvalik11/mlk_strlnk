import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';

abstract class NewsRepository {
  Future<Either<Failure, Page<NewsItem>>> getNewsList({
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, NewsItem>> getNewsById(String id);
}
