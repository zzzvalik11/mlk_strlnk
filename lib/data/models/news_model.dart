import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';

part 'news_model.freezed.dart';
part 'news_model.g.dart';

@freezed
class NewsModel with _$NewsModel {
  const NewsModel._();

  const factory NewsModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'summary') required String summary,
    @JsonKey(name: 'imageUrl') String? imageUrl,
    @JsonKey(name: 'publishedAt') required DateTime publishedAt,
    @JsonKey(name: 'readCount') int? readCount,
    @JsonKey(name: 'tags') @Default([]) List<String> tags,
  }) = _NewsModel;

  factory NewsModel.fromJson(Map<String, dynamic> json) =>
      _$NewsModelFromJson(json);

  NewsItem toDomain() {
    return NewsItem(
      id: id,
      title: title,
      summary: summary,
      imageUrl: imageUrl,
      publishedAt: publishedAt,
      readCount: readCount,
      tags: tags,
    );
  }

  factory NewsModel.fromDomain(NewsItem newsItem) {
    return NewsModel(
      id: newsItem.id,
      title: newsItem.title,
      summary: newsItem.summary,
      imageUrl: newsItem.imageUrl,
      publishedAt: newsItem.publishedAt,
      readCount: newsItem.readCount,
      tags: newsItem.tags,
    );
  }
}
