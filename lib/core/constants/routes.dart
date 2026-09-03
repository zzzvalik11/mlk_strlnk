class Routes {
  Routes._();

  /// Main tabs
  static const String home = '/';
  static const String payment = '/payment';
  static const String news = '/news';
  static const String support = '/support';

  /// Screens
  static const String topUp = '/top_up';
  static const String history = '/history';
  static const String newsDetail = '/news/:id';
  static const String paymentDetail = '/payment/:id';

  /// Auth
  static const String login = '/login';
  static const String quickLogin = '/quick_login';
  static const String authMethodSelection = '/auth_method_selection';

  /// App
  static const String promisedPayment = '/promised_payment';
  static const String settings = '/settings';
  static const String services = '/services';
  static const String notifications = '/notifications';

  /// Payment callback — 3DS / возврат из платёжной формы РСБ.
  /// Параметры query: status, result_code, rrn, approval_code, message
  static const String paymentCallback = '/payment/callback';
}
