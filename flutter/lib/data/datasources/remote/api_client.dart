import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:telecom_dashboard/core/constants/app_constants.dart';
import 'package:telecom_dashboard/data/local/storage_service.dart';

/// Centralised HTTP client built on [Dio].
///
/// Provides:
/// - **Auth interceptor** — injects the Bearer token from [StorageService].
/// - **Error-logging interceptor** — logs every DioException for debugging.
/// - Convenience [get] / [post] / [put] methods.
class ApiClient {
  late final Dio _dio;
  final StorageService _storageService;

  ApiClient({
    required StorageService storageService,
    String? baseUrl,
  }) : _storageService = storageService {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor,
      _errorLoggingInterceptor,
    ]);
  }

  /// Underlying [Dio] instance (exposed for datasources that need raw access).
  Dio get dio => _dio;

  // ------------------------------------------------------------------
  // Interceptors
  // ------------------------------------------------------------------

  InterceptorsWrapper get _authInterceptor => InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storageService
              .getString(AppConstants.authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] =
                '${AppConstants.authHeaderPrefix}$token';
          }
          handler.next(options);
        },
      );

  InterceptorsWrapper get _errorLoggingInterceptor =>
      InterceptorsWrapper(
        onError: (error, handler) {
          log(
            '[ApiClient] ${error.type} — ${error.requestOptions.path} '
            '${error.response?.statusCode}: ${error.message}',
            name: 'ApiClient',
            error: error,
          );
          handler.next(error);
        },
      );

  // ------------------------------------------------------------------
  // Convenience methods
  // ------------------------------------------------------------------

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post<T>(
      path,
      data: body,
      queryParameters: queryParameters,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.put<T>(
      path,
      data: body,
      queryParameters: queryParameters,
    );
  }

  /// Sends a multipart/form-data request (e.g. file uploads).
  Future<Response<T>> postMultipart<T>(
    String path, {
    required List<MultipartFile> files,
    Map<String, dynamic>? fields,
    ProgressCallback? onSendProgress,
  }) {
    final formData = FormData.fromMap({
      if (fields != null) ...fields,
      for (final file in files)
        'files': file,
    });

    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }
}
