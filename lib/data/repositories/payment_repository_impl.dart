import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'package:telecom_dashboard/core/errors/failures.dart';
import 'package:telecom_dashboard/data/datasources/remote/payment_remote_source.dart';
import 'package:telecom_dashboard/domain/entities/payment_link.dart';
import 'package:telecom_dashboard/domain/entities/payment_result.dart';
import 'package:telecom_dashboard/domain/repositories/payment_repository.dart';

/// Реализация платёжного репозитория.
/// Преобразует JSON-ответы remote source в доменные сущности.
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteSource _remoteSource;

  PaymentRepositoryImpl({required PaymentRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<Either<Failure, PaymentLink>> getPayLink({
    required int accountId,
    required double amount,
    PaymentMethod method = PaymentMethod.card,
  }) async {
    try {
      final json = await _remoteSource.getPayLink(
        accountId: accountId,
        amount: amount,
        paymentMethod: method.name,
      );

      final type = json['type'] as String?;
      if (type == 'sbp') {
        return right(PaymentLink.fromJson(json));
      }

      // По умолчанию — карточная оплата
      return right(PaymentLink.fromJson({
        ...json,
        'type': 'card',
      }));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> getCardPaymentStatus({
    required String transactionId,
  }) async {
    try {
      final json = await _remoteSource.getCardPaymentStatus(
        transactionId: transactionId,
        clientIp: '0.0.0.0',
      );
      return right(PaymentResult.fromJson(json));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> reverseCardPayment({
    required String transactionId,
  }) async {
    try {
      final json = await _remoteSource.reverseCardPayment(
        transactionId: transactionId,
      );
      return right(PaymentResult.fromJson(json));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> refundCardPayment({
    required String transactionId,
    double? amount,
  }) async {
    try {
      final json = await _remoteSource.refundCardPayment(
        transactionId: transactionId,
        amount: amount,
      );
      return right(PaymentResult.fromJson(json));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> getSbpPaymentStatus({
    required String orderId,
  }) async {
    try {
      final json = await _remoteSource.getSbpPaymentStatus(orderId: orderId);
      return right(PaymentResult.fromJson({
        'success': json['success'],
        'result_code': json['status'] != 'PAID' ? '000' : null,
        'message': json['status'],
      }));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> cancelSbpPayment({
    required String orderId,
  }) async {
    try {
      final json = await _remoteSource.cancelSbpPayment(orderId: orderId);
      return right(PaymentResult.fromJson({
        'success': json['success'],
        'message': json['message'],
      }));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> refundSbpPayment({
    required String orderId,
    double? amount,
  }) async {
    try {
      final json = await _remoteSource.refundSbpPayment(
        orderId: orderId,
        amount: amount,
      );
      return right(PaymentResult.fromJson({
        'success': json['success'],
        'message': json['message'],
      }));
    } on DioException catch (e) {
      return left(Failure.network(message: e.message ?? 'Ошибка сети'));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
