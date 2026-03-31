import '../../../../core/errors/app_exception.dart';
import '../../domain/models/payment_intent.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/payment_status.dart';
import '../../domain/models/payment_webhook_event.dart';
import '../../domain/repositories/payments_repository.dart';
import '../providers/click_payment_adapter.dart';
import '../providers/payme_payment_adapter.dart';
import '../providers/payment_provider_adapter.dart';

class FakePaymentsRepository implements PaymentsRepository {
  final Map<String, PaymentIntent> _intents = <String, PaymentIntent>{};

  late final Map<PaymentMethod, PaymentProviderAdapter> _adapters =
      <PaymentMethod, PaymentProviderAdapter>{
        PaymentMethod.click: ClickPaymentAdapter(),
        PaymentMethod.payme: PaymePaymentAdapter(),
      };

  @override
  Future<PaymentIntent> createBookingPaymentIntent({
    required String bookingId,
    required int amountUzs,
    required PaymentMethod method,
  }) async {
    if (amountUzs <= 0) {
      throw const AppException('Payment amount must be greater than zero.');
    }

    final adapter = _adapters[method];
    if (adapter == null) {
      throw const AppException('Payment method is not supported.');
    }

    final id = 'pi_${DateTime.now().millisecondsSinceEpoch}';
    final checkoutUrl = await adapter.createCheckout(
      paymentIntentId: id,
      amountUzs: amountUzs,
    );

    final intent = PaymentIntent(
      id: id,
      bookingId: bookingId,
      amountUzs: amountUzs,
      method: method,
      status: PaymentStatus.pending,
      checkoutUrl: checkoutUrl,
      createdAt: DateTime.now(),
    );

    _intents[id] = intent;
    return intent;
  }

  @override
  Future<PaymentStatus> getPaymentStatus(String paymentIntentId) async {
    final intent = _intents[paymentIntentId];
    if (intent == null) {
      throw const AppException('Payment intent not found.');
    }

    final adapter = _adapters[intent.method];
    if (adapter == null) {
      throw const AppException('Payment provider is not configured.');
    }

    final status = await adapter.pollStatus(paymentIntentId);
    _intents[paymentIntentId] = intent.copyWith(status: status);
    return status;
  }

  @override
  Future<PaymentStatus> processWebhook(PaymentWebhookEvent event) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final intent = _intents[event.externalTransactionId];
    if (intent == null) {
      throw const AppException('Unknown external transaction id.');
    }

    if (intent.method != event.method) {
      throw const AppException(
        'Webhook provider does not match payment intent.',
      );
    }

    final updated = intent.copyWith(status: event.status);
    _intents[event.externalTransactionId] = updated;
    return updated.status;
  }
}
