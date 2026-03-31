import '../../domain/models/payment_method.dart';
import '../../domain/models/payment_status.dart';

abstract interface class PaymentProviderAdapter {
  PaymentMethod get method;

  Future<String> createCheckout({
    required String paymentIntentId,
    required int amountUzs,
  });

  Future<PaymentStatus> pollStatus(String paymentIntentId);
}
