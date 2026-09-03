import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';

/// Источник данных для SMS-уведомлений (Devino Telecom через бэкенд-прокси).
class SmsRemoteSource {
  final ApiClient _apiClient;

  SmsRemoteSource({required this._apiClient});

  /// Отправить SMS.
  /// POST /v1/sms/send
  Future<Map<String, dynamic>> sendSms({
    required String phone,
    required String message,
    String? sender,
  }) async {
    final body = <String, dynamic>{'phone': phone, 'message': message};
    if (sender != null) body['sender'] = sender;
    final response = await _apiClient.post('/v1/sms/send', body: body);
    return response.data as Map<String, dynamic>;
  }

  /// Статус доставки SMS.
  /// GET /v1/sms/status/{smsId}
  Future<Map<String, dynamic>> getSmsStatus({required String smsId}) async {
    final response = await _apiClient.get('/v1/sms/status/$smsId');
    return response.data as Map<String, dynamic>;
  }

  /// Баланс SMS-шлюза.
  /// GET /v1/sms/balance
  Future<Map<String, dynamic>> getSmsBalance() async {
    final response = await _apiClient.get('/v1/sms/balance');
    return response.data as Map<String, dynamic>;
  }
}
