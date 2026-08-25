import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/support_ticket_model.dart';

/// Remote data source for support-ticket-related API calls.
class SupportRemoteSource {
  final ApiClient _apiClient;

  SupportRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// POST /v1/support/send-email — обращение в техподдержку.
  Future<SupportTicketModel> createTicket({
    required String subject,
    required String description,
  }) async {
    final response = await _apiClient.post(
      '/v1/support/send-email',
      body: {
        'subject': subject,
        'message': description,
      },
    );
    return SupportTicketModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// GET /v1/support/tickets — список обращений.
  Future<List<SupportTicketModel>> getTickets() async {
    final response = await _apiClient.get('/v1/support/tickets');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
