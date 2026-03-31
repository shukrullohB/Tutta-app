import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../domain/models/payment_intent.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/payment_status.dart';
import '../../domain/models/payment_webhook_event.dart';
import '../../domain/repositories/payments_repository.dart';

class ApiPaymentsRepository implements PaymentsRepository {
  const ApiPaymentsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<PaymentIntent> createBookingPaymentIntent({
    required String bookingId,
    required int amountUzs,
    required PaymentMethod method,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.paymentsIntents,
      data: <String, dynamic>{
        'booking': int.tryParse(bookingId) ?? bookingId,
        'provider': method.name,
        'currency': 'UZS',
      },
    );

    return result.when(
      success: (data) => _mapPaymentIntent(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  @override
  Future<PaymentStatus> getPaymentStatus(String paymentIntentId) async {
    final result = await _apiClient.get(
      ApiEndpoints.paymentIntentById(paymentIntentId),
    );

    return result.when(
      success: (data) {
        final payload = ApiResponseParser.extractMap(data);
        final rawStatus = payload['status'];
        return _statusFromServer(rawStatus);
      },
      failure: _throwFailure,
    );
  }

  @override
  Future<PaymentStatus> processWebhook(PaymentWebhookEvent event) async {
    final webhookSecret = const String.fromEnvironment(
      'PAYMENT_WEBHOOK_SECRET',
      defaultValue: '',
    );

    final result = await _apiClient.post(
      ApiEndpoints.paymentWebhook(event.method.name),
      data: <String, dynamic>{
        'provider_payment_id': event.externalTransactionId,
        'status': event.status.name,
        'payload': <String, dynamic>{},
      },
      headers: <String, String>{
        if (webhookSecret.isNotEmpty) 'X-Webhook-Secret': webhookSecret,
      },
    );

    return result.when(
      success: (data) {
        final payload = ApiResponseParser.extractMap(data);
        final rawStatus = payload['status'];
        return _statusFromServer(rawStatus);
      },
      failure: _throwFailure,
    );
  }

  PaymentIntent _mapPaymentIntent(Map<String, dynamic> payload) {
    final providerRaw = payload['provider']?.toString().toLowerCase().trim();
    final method = providerRaw == PaymentMethod.payme.name
        ? PaymentMethod.payme
        : PaymentMethod.click;

    final amountRaw = payload['amount'];
    final amount = amountRaw is num
        ? amountRaw.toInt()
        : int.tryParse(amountRaw?.toString() ?? '') ?? 0;

    return PaymentIntent(
      id: payload['id'].toString(),
      bookingId: payload['booking_id']?.toString() ?? '',
      amountUzs: amount,
      method: method,
      status: _statusFromServer(payload['status']),
      checkoutUrl: payload['checkout_url']?.toString() ?? '',
      createdAt: DateTime.tryParse(payload['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  PaymentStatus _statusFromServer(Object? rawStatus) {
    if (rawStatus is String) {
      final normalized = rawStatus.toLowerCase().trim();
      for (final status in PaymentStatus.values) {
        if (status.name == normalized) {
          return status;
        }
      }
    }

    throw const AppException('Unknown payment status from server.');
  }

  Never _throwFailure(Failure failure) {
    throw AppException(
      failure.message,
      code: failure.code,
      statusCode: failure.statusCode,
    );
  }
}
