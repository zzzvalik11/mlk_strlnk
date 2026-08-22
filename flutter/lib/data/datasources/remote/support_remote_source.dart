import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/models/support_ticket_model.dart';

/// Remote data source for support-ticket-related API calls.
class SupportRemoteSource {
  final ApiClient _apiClient;

  SupportRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// `POST /support` → creates a ticket and returns the DTO.
  Future<SupportTicketModel> createTicket({
    required String subject,
    required String description,
  }) async {
    final response = await _apiClient.post(
      '/support',
      body: {
        'subject': subject,
        'description': description,
      },
    );
    return SupportTicketModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `GET /support` → list of the user's tickets.
  Future<List<SupportTicketModel>> getMyTickets() async {
    final response = await _apiClient.get('/support');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}