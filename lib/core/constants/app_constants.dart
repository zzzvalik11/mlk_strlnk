class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Auth
  static const String authTokenKey = 'telecom_auth';
  static const String authHeaderPrefix = 'Bearer ';
  static const String tokenExpiryKey = 'telecom_token_expiry';
  static const String authMethodKey = 'telecom_auth_method';
  static const String firstLoginDoneKey = 'telecom_first_login_done';
  static const String isLockedKey = 'telecom_is_locked';
  static const String isMockUserKey = 'telecom_is_mock_user';
  static const Duration tokenValidity = Duration(days: 365);

  // Pagination
  static const int defaultPageLimit = 20;

  // Cache
  static const int cacheTtlSeconds = 300;

  // Deep links / Payment callback
  /// URL scheme приложения (используется для возврата из 3DS РСБ).
  static const String deepLinkScheme = 'starlink';

  /// Паттерн URL, который перехватывается в WebView после завершения оплаты.
  /// Бэкенд должен сконфигурировать этот URL как returnUrl при создании транзакции.
  static const String paymentCallbackHost = 'payment-callback.starlink.app';
  static const String paymentCallbackPath = '/callback';
}
