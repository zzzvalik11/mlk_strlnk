import 'package:fpdart/fpdart.dart';

import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/payment_link.dart';
import 'package:telecom_dashboard/domain/entities/payment_result.dart';
import 'package:telecom_dashboard/domain/entities/sms_status.dart';
import 'package:telecom_dashboard/domain/repositories/payment_repository.dart';
import 'package:telecom_dashboard/domain/repositories/sms_repository.dart';

/// Использовать случай: получить ссылку на оплату.
class GetPayLinkUseCase {
  final PaymentRepository _repository;

  const GetPayLinkUseCase(this._repository);

  Future<Either<Failure, PaymentLink>> call({
    required int accountId,
    required double amount,
    PaymentMethod method = PaymentMethod.card,
  }) {
    return _repository.getPayLink(
      accountId: accountId,
      amount: amount,
      method: method,
    );
  }
}

/// Использовать случай: проверить статус карточного платежа.
class CheckCardPaymentStatusUseCase {
  final PaymentRepository _repository;

  const CheckCardPaymentStatusUseCase(this._repository);

  Future<Either<Failure, PaymentResult>> call({
    required String transactionId,
  }) {
    return _repository.getCardPaymentStatus(transactionId: transactionId);
  }
}

/// Использовать случай: отправить SMS-уведомление.
class SendSmsUseCase {
  final SmsRepository _repository;

  const SendSmsUseCase(this._repository);

  Future<Either<Failure, SmsSendResult>> call({
    required String phone,
    required String message,
    String? sender,
  }) {
    return _repository.sendSms(phone: phone, message: message, sender: sender);
  }
}
