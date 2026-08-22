import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/news_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/repositories/news_repository.dart';

/// [NewsRepository] implementation backed by the remote API.
class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteSource _remoteSource;

  NewsRepositoryImpl({required NewsRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<Either<Failure, Page<NewsItem>>> getNewsList({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final models = await _remoteSource.getNewsList(
        page: page,
        limit: limit,
      );
      final entities = models.map((m) => m.toDomain()).toList();

      // The mock API returns a flat list.  Wrap it in a [Page] object.
      final total = entities.length;
      final domainPage = Page<NewsItem>(
        items: entities,
        total: total,
        page: page,
        limit: limit,
        hasMore: false,
      );
      return right(domainPage);
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NewsItem>> getNewsById(String id) async {
    try {
      final model = await _remoteSource.getNewsById(id);
      return right(model.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
