import 'package:dio/dio.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';

/// Maps [DioException] to the appropriate [Failure] type.
class DioExceptionMapper {
  DioExceptionMapper._();

  static Failure map(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const Failure.network(
          message: 'Превышено время ожидания соединения',
        );

      case DioExceptionType.connectionError:
        return const Failure.network(message: 'Нет подключения к интернету');

      case DioExceptionType.badResponse:
        return _mapBadResponse(exception);

      case DioExceptionType.badCertificate:
        return const Failure.network(
          message: 'Ошибка сертификата безопасности',
        );

      case DioExceptionType.cancel:
        return const Failure.unknown(message: 'Запрос был отменён');

      case DioExceptionType.unknown:
        return Failure.unknown(
          message: exception.message ?? 'Неизвестная ошибка',
        );
    }
  }

  static Failure _mapBadResponse(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final message = _extractMessage(exception);

    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      if (statusCode == 422) {
        return Failure.validation(message: message);
      }
      return Failure.server(statusCode: statusCode, message: message);
    }

    if (statusCode != null && statusCode >= 500) {
      return Failure.server(statusCode: statusCode, message: message);
    }

    return Failure.server(statusCode: statusCode ?? 0, message: message);
  }

  static String _extractMessage(DioException exception) {
    try {
      final data = exception.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'Ошибка сервера';
      }
    } catch (_) {
      // fall through
    }
    return 'Ошибка сервера';
  }
}
