import 'package:freezed_annotation/freezed_annotation.dart';

import 'payment_method.dart';
import 'payment_status.dart';

part 'payment_intent.freezed.dart';
part 'payment_intent.g.dart';

@freezed
class PaymentIntent with _$PaymentIntent {
  const factory PaymentIntent({
    required String id,
    required String bookingId,
    required int amountUzs,
    required PaymentMethod method,
    required PaymentStatus status,
    required String checkoutUrl,
    required DateTime createdAt,
  }) = _PaymentIntent;

  factory PaymentIntent.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentFromJson(json);
}
