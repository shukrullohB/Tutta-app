import 'payment_method.dart';
import 'payment_status.dart';

class PaymentWebhookEvent {
  const PaymentWebhookEvent({
    required this.method,
    required this.externalTransactionId,
    required this.status,
  });

  final PaymentMethod method;
  final String externalTransactionId;
  final PaymentStatus status;
}
