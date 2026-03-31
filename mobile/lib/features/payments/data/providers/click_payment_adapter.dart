import '../../domain/models/payment_method.dart';
import '../../domain/models/payment_status.dart';
import 'payment_provider_adapter.dart';

class ClickPaymentAdapter implements PaymentProviderAdapter {
  final Map<String, int> _pollCounter = <String, int>{};

  @override
  PaymentMethod get method => PaymentMethod.click;

  @override
  Future<String> createCheckout({
    required String paymentIntentId,
    required int amountUzs,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _pollCounter[paymentIntentId] = 0;
    return 'https://checkout.click.uz/pay/$paymentIntentId?amount=$amountUzs';
  }

  @override
  Future<PaymentStatus> pollStatus(String paymentIntentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final current = (_pollCounter[paymentIntentId] ?? 0) + 1;
    _pollCounter[paymentIntentId] = current;

    if (current <= 2) {
      return PaymentStatus.processing;
    }
    return PaymentStatus.succeeded;
  }
}
