import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';

part 'news_model.freezed.dart';
part 'news_model.g.dart';

@freezed
sealed class NewsModel with _$NewsModel {
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
}

extension NewsModelX on NewsModel {
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
}

extension NewsModelFromDomain on NewsItem {
  NewsModel toModel() {
    return NewsModel(
      id: id,
      title: title,
      summary: summary,
      imageUrl: imageUrl,
      publishedAt: publishedAt,
      readCount: readCount,
      tags: tags,
    );
  }
}
