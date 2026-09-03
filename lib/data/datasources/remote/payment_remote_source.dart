import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';

/// Источник данных для платёжных операций (РСБ ECOMM + СБП).
/// Все запросы идут через наш бэкенд-прокси.
class PaymentRemoteSource {
  final ApiClient _apiClient;

  PaymentRemoteSource({required this._apiClient});

  /// Получить ссылку на оплату.
  /// GET /v1/subscriber/accounts/{accountId}/pay-link
  Future<Map<String, dynamic>> getPayLink({
    required int accountId,
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await _apiClient.get(
      '/v1/subscriber/accounts/$accountId/pay-link',
      queryParameters: {'amount': amount, 'payment_method': paymentMethod},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Зарегистрировать SMS-транзакцию (РСБ).
  /// POST /v1/payments/card/register
  Future<Map<String, dynamic>> registerCardPayment({
    required Map<String, dynamic> body,
  }) async {
    final response = await _apiClient.post(
      '/v1/payments/card/register',
      body: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Проверить статус карточного платежа (РСБ).
  /// POST /v1/payments/card/status
  Future<Map<String, dynamic>> getCardPaymentStatus({
    required String transactionId,
    required String clientIp,
  }) async {
    final response = await _apiClient.post(
      '/v1/payments/card/status',
      body: {
        'trans_id': transactionId,
        'client_ip_addr': clientIp,
        'server_version': '2.0',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Отменить транзакцию (РСБ).
  /// POST /v1/payments/card/reverse
  Future<Map<String, dynamic>> reverseCardPayment({
    required String transactionId,
  }) async {
    final response = await _apiClient.post(
      '/v1/payments/card/reverse',
      body: {'trans_id': transactionId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Возврат средств (РСБ).
  /// POST /v1/payments/card/refund
  Future<Map<String, dynamic>> refundCardPayment({
    required String transactionId,
    double? amount,
  }) async {
    final body = <String, dynamic>{'trans_id': transactionId};
    if (amount != null) body['amount'] = amount;
    final response = await _apiClient.post(
      '/v1/payments/card/refund',
      body: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Получить статус платежа СБП.
  /// GET /v1/payments/sbp/status/{orderId}
  Future<Map<String, dynamic>> getSbpPaymentStatus({
    required String orderId,
  }) async {
    final response = await _apiClient.get('/v1/payments/sbp/status/$orderId');
    return response.data as Map<String, dynamic>;
  }

  /// Отменить платеж СБП.
  /// GET /v1/payments/sbp/cancel/{orderId}
  Future<Map<String, dynamic>> cancelSbpPayment({
    required String orderId,
  }) async {
    final response = await _apiClient.get('/v1/payments/sbp/cancel/$orderId');
    return response.data as Map<String, dynamic>;
  }

  /// Возврат платежа СБП.
  /// POST /v1/payments/sbp/refund/{orderId}
  Future<Map<String, dynamic>> refundSbpPayment({
    required String orderId,
    double? amount,
  }) async {
    final body = <String, dynamic>{};
    if (amount != null) body['amount'] = amount;
    final response = await _apiClient.post(
      '/v1/payments/sbp/refund/$orderId',
      body: body,
    );
    return response.data as Map<String, dynamic>;
  }
}
