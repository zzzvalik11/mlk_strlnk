import 'package:telecom_dashboard/domain/entities/news_item.dart';

class NewsModel {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final DateTime publishedAt;
  final int? readCount;
  final List<String> tags;

  const NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.publishedAt,
    this.readCount,
    this.tags = const [],
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      imageUrl: json['imageUrl'] as String?,
      publishedAt: _parseDateTime(json['publishedAt']),
      readCount: json['readCount'] as int?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'readCount': readCount,
      'tags': tags,
    };
  }

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

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse DateTime from $value');
}
