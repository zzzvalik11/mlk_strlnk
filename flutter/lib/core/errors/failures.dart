import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@Freezed(unionKey: 'type')
sealed class Failure with _$Failure {
  const factory Failure.network({
    required String message,
  }) = NetworkFailure;

  const factory Failure.server({
    required int statusCode,
    required String message,
  }) = ServerFailure;

  const factory Failure.validation({
    required String message,
  }) = ValidationFailure;

  const factory Failure.cache({
    required String message,
  }) = CacheFailure;

  const factory Failure.unknown({
    required String message,
  }) = UnknownFailure;
}
