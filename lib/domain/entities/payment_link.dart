import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_link.freezed.dart';
part 'payment_link.g.dart';

/// Метод оплаты.
enum PaymentMethod {
  @JsonValue('card')
  card,

  @JsonValue('sbp')
  sbp,
}

/// Ссылка на оплату — ответ от бэкенда.
/// Может содержать URL платёжной формы РСБ или QR-ссылку СБП.
@freezed
sealed class PaymentLink with _$PaymentLink {
  /// Оплата банковской картой через РСБ ECOMM.
  const factory PaymentLink.card({
    @JsonKey(name: 'type')
    @Default(PaymentMethod.card)
    PaymentMethod type,
    @JsonKey(name: 'transaction_id')
    required String transactionId,
    @JsonKey(name: 'client_handler_url')
    required String clientHandlerUrl,
  }) = CardPaymentLink;

  /// Оплата через Систему быстрых платежей.
  const factory PaymentLink.sbp({
    @JsonKey(name: 'type')
    @Default(PaymentMethod.sbp)
    PaymentMethod type,
    @JsonKey(name: 'order_id')
    String? orderId,
    @JsonKey(name: 'qrcode_link')
    required String qrcodeLink,
    @JsonKey(name: 'qr_url')
    String? qrUrl,
  }) = SbpPaymentLink;

  factory PaymentLink.fromJson(Map<String, dynamic> json) =>
      _$PaymentLinkFromJson(json);
}
