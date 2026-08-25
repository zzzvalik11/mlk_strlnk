import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/sms_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/sms_status.dart';
import 'package:telecom_dashboard/domain/repositories/sms_repository.dart';

/// Реализация SMS-репозитория (Devino Telecom).
class SmsRepositoryImpl implements SmsRepository {
  final SmsRemoteSource _remoteSource;

  SmsRepositoryImpl({required SmsRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<Either<Failure, SmsSendResult>> sendSms({
    required String phone,
    required String message,
    String? sender,
  }) async {
    try {
      final json = await _remoteSource.sendSms(
        phone: phone,
        message: message,
        sender: sender,
      );
      return right(SmsSendResult.fromJson(json));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SmsDeliveryStatus>> getSmsStatus({
    required String smsId,
  }) async {
    try {
      final json = await _remoteSource.getSmsStatus(smsId: smsId);
      return right(SmsDeliveryStatus.fromJson(json));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getSmsBalance() async {
    try {
      final json = await _remoteSource.getSmsBalance();
      final balance = json['balance'] as num;
      return right(balance.toDouble());
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
