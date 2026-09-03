import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/news_model.dart';

/// Remote data source for news-related API calls.
/// Прокси к Starlink BSS (api.yaml v3.0.0).
class NewsRemoteSource {
  final ApiClient _apiClient;

  NewsRemoteSource({required this._apiClient});

  /// GET /v1/resources/news — список новостей.
  Future<List<NewsModel>> getNewsList() async {
    final response = await _apiClient.get('/v1/resources/news');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /v1/resources/news/{id} — новость по ID.
  Future<NewsModel> getNewsById(String id) async {
    final response = await _apiClient.get('/v1/resources/news/$id');
    return NewsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
