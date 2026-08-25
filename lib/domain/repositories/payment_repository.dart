import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/payment_link.dart';
import 'package:telecom_dashboard/domain/entities/payment_result.dart';

/// Репозиторий платёжных операций (РСБ ECOMM + СБП).
abstract class PaymentRepository {
  /// Получить ссылку на оплату (карта или СБП) для указанного счёта.
  Future<Either<Failure, PaymentLink>> getPayLink({
    required int accountId,
    required double amount,
    PaymentMethod method,
  });

  /// Проверить статус карточного платежа (РСБ).
  Future<Either<Failure, PaymentResult>> getCardPaymentStatus({
    required String transactionId,
  });

  /// Отменить транзакцию (РСБ, до закрытия дня).
  Future<Either<Failure, PaymentResult>> reverseCardPayment({
    required String transactionId,
  });

  /// Возврат средств (РСБ, после закрытия дня).
  Future<Either<Failure, PaymentResult>> refundCardPayment({
    required String transactionId,
    double? amount,
  });

  /// Получить статус платежа СБП.
  Future<Either<Failure, PaymentResult>> getSbpPaymentStatus({
    required String orderId,
  });

  /// Отменить платеж СБП.
  Future<Either<Failure, PaymentResult>> cancelSbpPayment({
    required String orderId,
  });

  /// Возврат платежа СБП.
  Future<Either<Failure, PaymentResult>> refundSbpPayment({
    required String orderId,
    double? amount,
  });
}
