import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_item.freezed.dart';
part 'news_item.g.dart';

@freezed
sealed class NewsItem with _$NewsItem {
  const factory NewsItem({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'summary') required String summary,
    @JsonKey(name: 'imageUrl') String? imageUrl,
    @JsonKey(name: 'publishedAt') required DateTime publishedAt,
    @JsonKey(name: 'readCount') int? readCount,
    @JsonKey(name: 'tags') @Default([]) List<String> tags,
  }) = _NewsItem;

  factory NewsItem.fromJson(Map<String, dynamic> json) =>
      _$NewsItemFromJson(json);
}
