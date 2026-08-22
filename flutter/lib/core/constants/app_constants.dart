class AppConstants {
  AppConstants._();

  /// API
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

  /// Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Auth
  static const String authTokenKey = 'telecom_auth';
  static const String authHeaderPrefix = 'Bearer ';

  /// Pagination
  static const int defaultPageLimit = 20;

  /// Cache
  static const int cacheTtlSeconds = 300;
}
