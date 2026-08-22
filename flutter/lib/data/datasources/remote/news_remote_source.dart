import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/news_model.dart';

/// Remote data source for news-related API calls.
class NewsRemoteSource {
  final ApiClient _apiClient;

  NewsRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// `GET /news?page=&limit=` → list of news DTOs.
  Future<List<NewsModel>> getNewsList({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/news',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /news/:id` → single news DTO.
  Future<NewsModel> getNewsById(String id) async {
    final response = await _apiClient.get('/news/$id');
    return NewsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
