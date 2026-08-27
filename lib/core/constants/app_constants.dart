import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // ─── Safe dotenv accessor ─────────────────────────────────
  // On web, .env may not exist (404). dotenv.load() is in try-catch,
  // but dotenv.env still throws NotInitializedError if load failed.
  // This helper catches that and returns null.
  static String? _env(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  // API
  static String get apiBaseUrl =>
      _env('API_BASE_URL') ?? 'http://10.0.2.2:3000/api';

  // СБП API (если не задан — используется apiBaseUrl)
  static String get sbpApiUrl =>
      _env('SBP_API_URL') ?? apiBaseUrl;

  // РСБ платёжный шлюз (если не заданы — запросы идут через apiBaseUrl)
  static String get rsbPaymentUrl =>
      _env('RSB_PAYMENT_URL') ?? apiBaseUrl;
  static String get rsbRegisterUrl =>
      _env('RSB_REGISTER_URL') ?? apiBaseUrl;

  // РСБ учётные данные
  static String get rsbMerchantName =>
      _env('RSB_MERCHANT_NAME') ?? '';
  static String get rsbTerminalId =>
      _env('RSB_TERMINAL_ID') ?? '';
  static String get rsbMerchantId =>
      _env('RSB_MERCHANT_ID') ?? '';
  static String get rsbSecretKey =>
      _env('RSB_SECRET_KEY') ?? '';

  // FCM
  static String get fcmServerKey =>
      _env('FCM_SERVER_KEY') ?? '';

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
  static const String deepLinkScheme = 'starlink';
  static const String paymentCallbackHost = 'payment-callback.starlink.app';
  static const String paymentCallbackPath = '/callback';
}
