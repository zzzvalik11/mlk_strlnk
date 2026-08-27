import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // API
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  // FCM
  static String get fcmServerKey =>
      dotenv.env['FCM_SERVER_KEY'] ?? '';

  // РСБ
  static String get rsbMerchantName =>
      dotenv.env['RSB_MERCHANT_NAME'] ?? '';
  static String get rsbTerminalId =>
      dotenv.env['RSB_TERMINAL_ID'] ?? '';
  static String get rsbMerchantId =>
      dotenv.env['RSB_MERCHANT_ID'] ?? '';
  static String get rsbSecretKey =>
      dotenv.env['RSB_SECRET_KEY'] ?? '';

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
