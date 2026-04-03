import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutta/core/network/api_client.dart';
import 'package:tutta/core/network/api_endpoints.dart';
import 'package:tutta/core/network/api_result.dart';
import 'package:tutta/features/auth/data/repositories/api_auth_repository.dart';
import 'package:tutta/features/bookings/data/repositories/api_booking_repository.dart';
import 'package:tutta/features/listings/data/repositories/api_listings_repository.dart';
import 'package:tutta/features/listings/domain/models/availability_day.dart';
import 'package:tutta/features/listings/domain/models/create_listing_input.dart';
import 'package:tutta/features/listings/domain/models/listing.dart';
import 'package:tutta/features/notifications/data/repositories/api_notifications_repository.dart';
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
      expect(call.path, ApiEndpoints.bookingsByRole('guest'));
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
      'bookings markCompleted hits complete endpoint and maps status',
      () async {
        final client = _RecordingApiClient();
        final repository = ApiBookingRepository(client);

        client.queuePost(
          ApiSuccess(<String, dynamic>{'detail': 'Booking completed.'}),
        );
        client.queueGet(
          ApiSuccess(<String, dynamic>{
            'results': <Map<String, dynamic>>[
              _bookingJson(id: 'b-3')..['status'] = 'completed',
            ],
          }),
        );

        final booking = await repository.markCompleted(
          bookingId: 'b-3',
          hostUserId: 'host-1',
        );

        final call = client.postCalls.single;
        expect(call.path, '/bookings/b-3/complete');
        expect(booking.status.name, 'completed');
      },
    );

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

    test('listings update maps request payload and response', () async {
      final client = _RecordingApiClient();
      final repository = ApiListingsRepository(client);

      client.queuePut(
        ApiSuccess(<String, dynamic>{
          'data': <String, dynamic>{
            'id': 101,
            'host_id': 12,
            'title': 'Updated listing',
            'description': 'Nice place',
            'location': 'Tashkent, Yunusabad',
            'city': 'Tashkent',
            'district': 'Yunusabad',
            'listing_type': 'home',
            'price_per_night': 500000,
            'max_guests': 3,
            'min_days': 1,
            'max_days': 10,
            'is_active': true,
            'images': <Map<String, dynamic>>[],
          },
        }),
      );

      final listing = await repository.updateListing(
        listingId: '101',
        input: const CreateListingInput(
          title: 'Updated listing',
          description: 'Nice place',
          city: 'Tashkent',
          district: 'Yunusabad',
          type: ListingType.homePart,
          amenities: <ListingAmenity>[],
          nightlyPriceUzs: 500000,
          maxGuests: 3,
          minDays: 1,
          maxDays: 10,
          showPhone: false,
        ),
      );

      final call = client.putCalls.single;
      expect(call.path, ApiEndpoints.listingManage('101'));
      expect(call.data, isA<FormData>());
      final formData = call.data as FormData;
      expect(
        formData.fields.any(
          (field) => field.key == 'listing_type' && field.value == 'home',
        ),
        isTrue,
      );
      expect(
        formData.fields.any(
          (field) => field.key == 'max_days' && field.value == '10',
        ),
        isTrue,
      );
      expect(listing.id, '101');
      expect(listing.city, 'Tashkent');
      expect(listing.district, 'Yunusabad');
    });

    test('listings availability upsert sends and maps payload', () async {
      final client = _RecordingApiClient();
      final repository = ApiListingsRepository(client);

      client.queuePut(
        ApiSuccess(<String, dynamic>{
          'results': <Map<String, dynamic>>[
            <String, dynamic>{
              'date': '2030-07-10',
              'is_available': false,
              'note': 'maintenance',
            },
          ],
        }),
      );

      final result = await repository.upsertAvailability(
        listingId: 'l-1',
        days: <AvailabilityDay>[
          AvailabilityDay(
            date: DateTime(2030, 7, 10),
            isAvailable: false,
            note: 'maintenance',
          ),
        ],
      );

      final call = client.putCalls.single;
      expect(call.path, ApiEndpoints.listingAvailability('l-1'));
      expect(call.data, isA<Map<String, dynamic>>());
      final payload = call.data as Map<String, dynamic>;
      expect(payload['days'], isA<List<dynamic>>());
      expect(result, hasLength(1));
      expect(result.first.isAvailable, isFalse);
    });

    test('notifications list and mark read use expected endpoints', () async {
      final client = _RecordingApiClient();
      final repository = ApiNotificationsRepository(client);

      client.queueGet(
        ApiSuccess(<String, dynamic>{
          'results': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 91,
              'type': 'system',
              'title': 'Welcome',
              'body': 'Hello',
              'is_read': false,
              'created_at': '2026-03-28T10:00:00.000Z',
              'payload': <String, dynamic>{},
            },
          ],
        }),
      );
      client.queuePost(
        ApiSuccess(<String, dynamic>{'detail': 'Notification marked as read.'}),
      );
      client.queuePost(
        ApiSuccess(<String, dynamic>{'detail': 'Push device registered.'}),
      );
      client.queuePost(
        ApiSuccess(<String, dynamic>{
          'detail': 'Push device unregistered.',
          'updated': 1,
        }),
      );

      final items = await repository.list();
      await repository.markRead('91');
      await repository.registerDeviceToken(
        token: 'fcm_token_123',
        platform: 'android',
        deviceId: 'device-1',
      );
      await repository.unregisterDeviceToken('fcm_token_123');

      expect(client.getCalls.last.path, ApiEndpoints.notifications);
      expect(client.postCalls[0].path, ApiEndpoints.notificationMarkRead('91'));
      expect(
        client.postCalls[1].path,
        ApiEndpoints.notificationsDeviceRegister(),
      );
      expect(
        client.postCalls[2].path,
        ApiEndpoints.notificationsDeviceUnregister(),
      );
      expect(items, hasLength(1));
      expect(items.first.id, '91');
      expect(items.first.isRead, isFalse);
    });
  });
}

Map<String, dynamic> _bookingJson({required String id, bool isPaid = false}) {
  return <String, dynamic>{
    'id': id,
    'listing': 'listing-1',
    'guest_id': 'guest-1',
    'host_id': 'host-1',
    'start_date': '2026-03-20',
    'end_date': '2026-03-22',
    'status': 'confirmed',
    'payment_required': true,
    'is_paid': isPaid,
    'payment_status': isPaid ? 'succeeded' : 'pending',
    'total_price': 300000,
    'guests_count': 2,
    'is_review_allowed': false,
  };
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(Dio());

  final List<_RecordedCall> getCalls = <_RecordedCall>[];
  final List<_RecordedCall> postCalls = <_RecordedCall>[];
  final List<_RecordedCall> putCalls = <_RecordedCall>[];
  final List<ApiResult<Map<String, dynamic>>> _queuedGets =
      <ApiResult<Map<String, dynamic>>>[];
  final List<ApiResult<Map<String, dynamic>>> _queuedPosts =
      <ApiResult<Map<String, dynamic>>>[];
  final List<ApiResult<Map<String, dynamic>>> _queuedPuts =
      <ApiResult<Map<String, dynamic>>>[];

  void queueGet(ApiResult<Map<String, dynamic>> result) {
    _queuedGets.add(result);
  }

  void queuePost(ApiResult<Map<String, dynamic>> result) {
    _queuedPosts.add(result);
  }

  void queuePut(ApiResult<Map<String, dynamic>> result) {
    _queuedPuts.add(result);
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
    Object? data,
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

  @override
  Future<ApiResult<Map<String, dynamic>>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    putCalls.add(
      _RecordedCall(
        path: path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );

    if (_queuedPuts.isEmpty) {
      throw StateError('No queued PUT response for $path');
    }
    return _queuedPuts.removeAt(0);
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
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headers;
}
