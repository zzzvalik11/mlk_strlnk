import 'package:fpdart/fpdart.dart';
import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/domain/entities/sms_status.dart';

/// Репозиторий SMS-уведомлений (Devino Telecom).
abstract class SmsRepository {
  /// Отправить SMS-сообщение.
  Future<Either<Failure, SmsSendResult>> sendSms({
    required String phone,
    required String message,
    String? sender,
  });

  /// Проверить статус доставки SMS.
  Future<Either<Failure, SmsDeliveryStatus>> getSmsStatus({
    required String smsId,
  });

  /// Получить баланс SMS-шлюза.
  Future<Either<Failure, double>> getSmsBalance();
}
