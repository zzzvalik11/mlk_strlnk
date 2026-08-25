import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/exceptions.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/local/user_local_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/news_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';
import 'package:telecom_dashboard/domain/entities/page.dart';
import 'package:telecom_dashboard/domain/repositories/news_repository.dart';

/// [NewsRepository] implementation backed by the remote API.
/// Returns mock data when the current user is the test user (039103).
class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteSource _remoteSource;
  final UserLocalSource _localSource;

  NewsRepositoryImpl({
    required NewsRemoteSource remoteSource,
    required UserLocalSource localSource,
  })  : _remoteSource = remoteSource,
        _localSource = localSource;

  @override
  Future<Either<Failure, Page<NewsItem>>> getNewsList({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (_localSource.isMockUser()) {
        final items = _createMockNews();
        return right(Page<NewsItem>(
          items: items,
          total: items.length,
          page: page,
          limit: limit,
          hasMore: false,
        ));
      }

      final models = await _remoteSource.getNewsList();
      final entities = models.map((m) => m.toDomain()).toList();
      final domainPage = Page<NewsItem>(
        items: entities,
        total: entities.length,
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
      if (_localSource.isMockUser()) {
        final all = _createMockNews();
        final match = all.where((n) => n.id == id).firstOrNull;
        if (match == null) {
          return left(const Failure.server(statusCode: 404, message: 'Новость не найдена'));
        }
        return right(match);
      }

      final model = await _remoteSource.getNewsById(id);
      return right(model.toDomain());
    } on DioException catch (e) {
      return left(DioExceptionMapper.map(e));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  // ── Mock news data ───────────────────────────────────────────

  List<NewsItem> _createMockNews() {
    return [
      NewsItem(
        id: 'n1',
        title: 'Новое тарифное предложение «Максимум»',
        summary: 'Скорость до 500 Мбит/с, более 200 ТВ-каналов и безлимитные звонки. Подключите уже сегодня!',
        publishedAt: DateTime(2025, 7, 10),
        readCount: 1250,
        tags: ['тарифы', 'акции'],
      ),
      NewsItem(
        id: 'n2',
        title: 'Технические работы 20 июля',
        summary: 'Уважаемые абоненты! 20 июля с 02:00 до 06:00 проводятся плановые технические работы. Возможны кратковременные перебои с интернетом.',
        publishedAt: DateTime(2025, 7, 8),
        readCount: 3400,
        tags: ['технические работы'],
      ),
      NewsItem(
        id: 'n3',
        title: 'Розыгрыш среди абонентов',
        summary: 'Оплатите услуги до конца месяца и участвуйте в розыгрыше smart-TV!',
        publishedAt: DateTime(2025, 7, 1),
        readCount: 890,
        tags: ['акции', 'розыгрыш'],
      ),
    ];
  }
}
