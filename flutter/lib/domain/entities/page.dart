import 'package:freezed_annotation/freezed_annotation.dart';

part 'page.freezed.dart';
part 'page.g.dart';

@freezed
@JsonSerializable(genericArgumentFactories: true)
class Page<T> with _$Page<T> {
  const factory Page({
    @JsonKey(name: 'items') required List<T> items,
    @JsonKey(name: 'total') required int total,
    @JsonKey(name: 'page') required int page,
    @JsonKey(name: 'limit') required int limit,
    @JsonKey(name: 'hasMore') required bool hasMore,
  }) = _Page<T>;

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PageFromJson<T>(json, fromJsonT);
}
