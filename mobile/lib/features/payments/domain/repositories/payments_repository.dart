import '../models/payment_intent.dart';
import '../models/payment_method.dart';
import '../models/payment_status.dart';
import '../models/payment_webhook_event.dart';

abstract interface class PaymentsRepository {
  Future<PaymentIntent> createBookingPaymentIntent({
    required String bookingId,
    required int amountUzs,
    required PaymentMethod method,
  });

  Future<PaymentStatus> getPaymentStatus(String paymentIntentId);

  Future<PaymentStatus> processWebhook(PaymentWebhookEvent event);
}
