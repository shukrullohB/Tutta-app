import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutta/core/network/api_client.dart';
import 'package:tutta/core/network/api_endpoints.dart';
import 'package:tutta/core/network/api_result.dart';
import 'package:tutta/features/auth/data/repositories/api_auth_repository.dart';
import 'package:tutta/features/bookings/data/repositories/api_booking_repository.dart';
import 'package:tutta/features/payments/data/repositories/api_payments_repository.dart';
import 'package:tutta/features/payments/domain/models/payment_method.dart';
import 'package:tutta/features/payments/domain/models/payment_status.dart';
import 'package:tutta/features/payments/domain/models/payment_webhook_event.dart';
import 'package:tutta/features/reviews/data/repositories/api_reviews_repository.dart';

void main() {
  group('API repositories contract mapping', () {
    test('auth login maps result envelope and request payload', () async {
      final client = _RecordingApiClient();
      final repository = ApiAuthRepository(client);

      client.queuePost(
        ApiSuccess(<String, dynamic>{
          'result': <String, dynamic>{
            'access': 'token-123',
            'refresh': 'refresh-123',
            'user': <String, dynamic>{
              'id': 1,
              'email': 'alice@example.com',
              'first_name': 'Alice',
              'last_name': 'Dev',
              'role': 'guest',
              'phone_number': '+998901112233',
            },
          },
        }),
      );

      final user = await repository.login(
        email: 'alice@example.com',
        password: 'StrongPass123!',
      );

      final call = client.postCalls.single;
      expect(call.path, ApiEndpoints.authLogin);
      expect(call.data, <String, dynamic>{
        'email': 'alice@example.com',
        'password': 'StrongPass123!',
      });
      expect(user.id, '1');
      expect(user.email, 'alice@example.com');
      expect(user.role, 'guest');
      expect(user.accessToken, 'token-123');
      expect(user.refreshToken, 'refresh-123');
    });

    test('bookings guest list accepts results envelope', () async {
      final client = _RecordingApiClient();
      final repository = ApiBookingRepository(client);

      client.queueGet(
        ApiSuccess(<String, dynamic>{
          'results': <Map<String, dynamic>>[_bookingJson(id: 'b-1')],
        }),
      );

      final bookings = await repository.getGuestBookings('guest-1');

      final call = client.getCalls.single;
      expect(call.path, ApiEndpoints.guestBookings('guest-1'));
      expect(bookings, hasLength(1));
      expect(bookings.first.id, 'b-1');
      expect(bookings.first.isPaid, isFalse);
    });

    test('bookings setPaymentStatus sends expected body', () async {
      final client = _RecordingApiClient();
      final repository = ApiBookingRepository(client);

      client.queuePost(
        ApiSuccess(<String, dynamic>{
          'data': _bookingJson(id: 'b-2', isPaid: true),
        }),
      );

      final booking = await repository.setPaymentStatus(
        bookingId: 'b-2',
        guestUserId: 'guest-2',
        paymentStatus: PaymentStatus.succeeded,
      );

      final call = client.postCalls.single;
      expect(call.path, ApiEndpoints.bookingPaymentStatus('b-2'));
      expect(call.data, <String, dynamic>{
        'guestUserId': 'guest-2',
        'paymentStatus': 'succeeded',
      });
      expect(booking.paymentStatus, PaymentStatus.succeeded);
      expect(booking.isPaid, isTrue);
    });

    test(
      'payments webhook sends idempotency headers and parses payload status',
      () async {
        final client = _RecordingApiClient();
        final repository = ApiPaymentsRepository(client);

        client.queuePost(
          ApiSuccess(<String, dynamic>{
            'payload': <String, dynamic>{'status': 'succeeded'},
          }),
        );

        final status = await repository.processWebhook(
          const PaymentWebhookEvent(
            method: PaymentMethod.click,
            externalTransactionId: 'txn-100',
            status: PaymentStatus.processing,
          ),
        );

        final call = client.postCalls.single;
        expect(call.path, ApiEndpoints.paymentWebhook('click'));
        expect(call.headers?['x-idempotency-key'], 'txn-100-processing-click');
        expect(
          call.headers?['x-tutta-signature'],
          'dev-signature:click:txn-100:processing',
        );
        expect(status, PaymentStatus.succeeded);
      },
    );

    test('reviews listing accepts list in data envelope', () async {
      final client = _RecordingApiClient();
      final repository = ApiReviewsRepository(client);

      client.queueGet(
        ApiSuccess(<String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'r-1',
              'bookingId': 'b-1',
              'listingId': 'l-1',
              'reviewerUserId': 'g-1',
              'hostUserId': 'h-1',
              'rating': 5,
              'comment': 'Great',
              'createdAt': '2026-03-10T10:00:00.000Z',
            },
          ],
        }),
      );

      final reviews = await repository.getByListing('l-1');

      final call = client.getCalls.single;
      expect(call.path, ApiEndpoints.reviewsByListing('l-1'));
      expect(reviews, hasLength(1));
      expect(reviews.first.rating, 5);
    });
  });
}

Map<String, dynamic> _bookingJson({required String id, bool isPaid = false}) {
  return <String, dynamic>{
    'id': id,
    'listingId': 'listing-1',
    'guestUserId': 'guest-1',
    'hostUserId': 'host-1',
    'checkInDate': '2026-03-20T14:00:00.000Z',
    'checkOutDate': '2026-03-22T11:00:00.000Z',
    'status': 'confirmed',
    'paymentRequired': true,
    'isPaid': isPaid,
    'paymentStatus': isPaid ? 'succeeded' : 'pending',
    'totalPriceUzs': 300000,
    'guestsCount': 2,
    'isReviewAllowed': false,
  };
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(Dio());

  final List<_RecordedCall> getCalls = <_RecordedCall>[];
  final List<_RecordedCall> postCalls = <_RecordedCall>[];
  final List<ApiResult<Map<String, dynamic>>> _queuedGets =
      <ApiResult<Map<String, dynamic>>>[];
  final List<ApiResult<Map<String, dynamic>>> _queuedPosts =
      <ApiResult<Map<String, dynamic>>>[];

  void queueGet(ApiResult<Map<String, dynamic>> result) {
    _queuedGets.add(result);
  }

  void queuePost(ApiResult<Map<String, dynamic>> result) {
    _queuedPosts.add(result);
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    getCalls.add(
      _RecordedCall(
        path: path,
        data: null,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );

    if (_queuedGets.isEmpty) {
      throw StateError('No queued GET response for $path');
    }
    return _queuedGets.removeAt(0);
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    postCalls.add(
      _RecordedCall(
        path: path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );

    if (_queuedPosts.isEmpty) {
      throw StateError('No queued POST response for $path');
    }
    return _queuedPosts.removeAt(0);
  }
}

class _RecordedCall {
  const _RecordedCall({
    required this.path,
    required this.data,
    required this.queryParameters,
    required this.headers,
  });

  final String path;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headers;
}
