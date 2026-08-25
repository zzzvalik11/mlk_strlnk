import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/api_client.dart';
import 'package:telecom_dashboard/data/datasources/remote/payment_remote_source.dart';
import 'package:telecom_dashboard/data/datasources/remote/sms_remote_source.dart';
import 'package:telecom_dashboard/data/repositories/payment_repository_impl.dart';
import 'package:telecom_dashboard/data/repositories/sms_repository_impl.dart';
import 'package:telecom_dashboard/domain/entities/payment_link.dart';
import 'package:telecom_dashboard/domain/entities/payment_result.dart';
import 'package:telecom_dashboard/domain/entities/sms_status.dart';
import 'package:telecom_dashboard/domain/repositories/payment_repository.dart';
import 'package:telecom_dashboard/domain/repositories/sms_repository.dart';
import 'package:telecom_dashboard/domain/usecases/payments/get_pay_link_usecase.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';

// ─── Data-Source Providers ────────────────────────────────────────

final paymentRemoteSourceProvider = Provider<PaymentRemoteSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentRemoteSource(apiClient: apiClient);
});

final smsRemoteSourceProvider = Provider<SmsRemoteSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SmsRemoteSource(apiClient: apiClient);
});

// ─── Repository Providers ────────────────────────────────────────

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    remoteSource: ref.watch(paymentRemoteSourceProvider),
  );
});

final smsRepositoryProvider = Provider<SmsRepository>((ref) {
  return SmsRepositoryImpl(
    remoteSource: ref.watch(smsRemoteSourceProvider),
  );
});

// ─── Use-Case Providers ──────────────────────────────────────────

final getPayLinkUseCaseProvider = Provider<GetPayLinkUseCase>((ref) {
  return GetPayLinkUseCase(ref.watch(paymentRepositoryProvider));
});

final checkCardPaymentStatusUseCaseProvider =
    Provider<CheckCardPaymentStatusUseCase>((ref) {
  return CheckCardPaymentStatusUseCase(ref.watch(paymentRepositoryProvider));
});

final sendSmsUseCaseProvider = Provider<SendSmsUseCase>((ref) {
  return SendSmsUseCase(ref.watch(smsRepositoryProvider));
});

// ─── Payment Providers ────────────────────────────────────────────

/// Провайдер получения ссылки на оплату.
final payLinkProvider = FutureProvider.autoDispose
    .family<PaymentLink, ({int accountId, double amount, PaymentMethod method})>(
        (ref, args) async {
  final useCase = ref.watch(getPayLinkUseCaseProvider);
  final result = await useCase.call(
    accountId: args.accountId,
    amount: args.amount,
    method: args.method,
  );
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (link) => link,
  );
});

/// Провайдер проверки статуса платежа (РСБ).
final cardPaymentStatusProvider =
    FutureProvider.autoDispose.family<PaymentResult, String>(
        (ref, transactionId) async {
  final useCase = ref.watch(checkCardPaymentStatusUseCaseProvider);
  final result = await useCase.call(transactionId: transactionId);
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (paymentResult) => paymentResult,
  );
});

/// Провайдер отправки SMS.
final sendSmsProvider = FutureProvider.autoDispose
    .family<SmsSendResult, ({String phone, String message})>((ref, args) async {
  final useCase = ref.watch(sendSmsUseCaseProvider);
  final result = await useCase.call(
    phone: args.phone,
    message: args.message,
  );
  return result.fold(
    (Failure failure) => throw Exception(_failureMessage(failure)),
    (smsResult) => smsResult,
  );
});

String _failureMessage(Failure failure) {
  return failure.when(
    network: (m) => m,
    server: (_, m) => m,
    validation: (m) => m,
    cache: (m) => m,
    unknown: (m) => m,
  );
}
