import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../../payments/domain/models/payment_status.dart';
import '../../domain/models/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  const ApiBookingRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Booking?> getById(String bookingId) async {
    final result = await _apiClient.get(ApiEndpoints.bookings);

    return result.when(
      success: (data) {
        final list = ApiResponseParser.extractList(data);
        final payload = list.firstWhere(
          (item) => item['id'].toString() == bookingId,
          orElse: () => <String, dynamic>{},
        );
        if (payload.isEmpty) {
          return null;
        }
        return _mapBooking(payload);
      },
      failure: (failure) {
        if (failure.statusCode == 404) {
          return null;
        }
        _throwFailure(failure);
      },
    );
  }

  @override
  Future<Booking> createBookingRequest({
    required String listingId,
    required String guestUserId,
    required String hostUserId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required int totalPriceUzs,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.bookings,
      data: <String, dynamic>{
        'listing': int.tryParse(listingId) ?? listingId,
        'start_date': checkIn.toIso8601String().split('T').first,
        'end_date': checkOut.toIso8601String().split('T').first,
        'guests_count': guests,
      },
    );

    return result.when(
      success: (data) async {
        final created = ApiResponseParser.extractMap(data);
        final createdId = created['id']?.toString();
        if (createdId == null || createdId.isEmpty) {
          throw const AppException('Invalid booking response from server.');
        }
        final hydrated = await getById(createdId);
        if (hydrated == null) {
          throw const AppException('Booking created but could not be loaded.');
        }
        return hydrated;
      },
      failure: _throwFailure,
    );
  }

  @override
  Future<List<Booking>> getGuestBookings(String guestUserId) async {
    final result = await _apiClient.get(ApiEndpoints.bookingsByRole('guest'));

    return result.when(
      success: (data) => ApiResponseParser.extractList(
        data,
      ).map(_mapBooking).toList(growable: false),
      failure: _throwFailure,
    );
  }

  @override
  Future<List<Booking>> getHostBookings(String hostUserId) async {
    final result = await _apiClient.get(ApiEndpoints.bookingsByRole('host'));

    return result.when(
      success: (data) => ApiResponseParser.extractList(
        data,
      ).map(_mapBooking).toList(growable: false),
      failure: _throwFailure,
    );
  }

  @override
  Future<Booking> confirmBooking({
    required String bookingId,
    required String hostUserId,
  }) {
    return _runAction(
      bookingId: bookingId,
      pathSuffix: 'confirm',
    );
  }

  @override
  Future<Booking> rejectBooking({
    required String bookingId,
    required String hostUserId,
  }) {
    return _runAction(
      bookingId: bookingId,
      pathSuffix: 'cancel',
    );
  }

  @override
  Future<Booking> cancelByGuest({
    required String bookingId,
    required String guestUserId,
  }) {
    return _runAction(
      bookingId: bookingId,
      pathSuffix: 'cancel',
    );
  }

  @override
  Future<Booking> markCompleted({
    required String bookingId,
    required String hostUserId,
  }) {
    return _runAction(
      bookingId: bookingId,
      pathSuffix: 'complete',
    );
  }

  @override
  Future<Booking> setPaymentStatus({
    required String bookingId,
    required String guestUserId,
    required PaymentStatus paymentStatus,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.bookingPaymentStatus(bookingId),
      data: <String, dynamic>{
        'guestUserId': guestUserId,
        'paymentStatus': paymentStatus.name,
      },
    );

    return result.when(
      success: (data) {
        final payload = ApiResponseParser.extractMap(data);
        if (payload.isNotEmpty) {
          return _mapBooking(payload);
        }
        return Booking(
          id: bookingId,
          listingId: '',
          guestUserId: guestUserId,
          hostUserId: '',
          checkInDate: DateTime.now(),
          checkOutDate: DateTime.now().add(const Duration(days: 1)),
          status: BookingStatus.confirmed,
          paymentRequired: true,
          isPaid: paymentStatus == PaymentStatus.succeeded,
          paymentStatus: paymentStatus,
          totalPriceUzs: 0,
          guestsCount: 1,
          isReviewAllowed: false,
        );
      },
      failure: _throwFailure,
    );
  }

  Future<Booking> _runAction({
    required String bookingId,
    required String pathSuffix,
  }) async {
    final result = await _apiClient.post(
      '${ApiEndpoints.bookingById(bookingId)}/$pathSuffix',
      data: <String, dynamic>{},
    );

    return result.when(
      success: (data) async {
        final updated = await getById(bookingId);
        if (updated == null) {
          throw const AppException('Booking updated but could not be loaded.');
        }
        return updated;
      },
      failure: _throwFailure,
    );
  }

  Booking _mapBooking(Map<String, dynamic> payload) {
    final startDateRaw = payload['start_date']?.toString();
    final endDateRaw = payload['end_date']?.toString();
    final statusRaw = payload['status']?.toString().toLowerCase().trim();
    final totalPriceRaw = payload['total_price'];
    final paymentStatusRaw = payload['payment_status']?.toString();

    final totalPrice = totalPriceRaw is num
        ? totalPriceRaw.toInt()
        : int.tryParse(totalPriceRaw?.toString() ?? '') ?? 0;

    final isPaid = payload['is_paid'] == true ||
        (paymentStatusRaw != null &&
            paymentStatusRaw.toLowerCase() == PaymentStatus.succeeded.name);

    return Booking(
      id: payload['id'].toString(),
      listingId: payload['listing']?.toString() ?? '',
      guestUserId: payload['guest_id']?.toString() ?? '',
      hostUserId: payload['host_id']?.toString() ?? '',
      checkInDate: DateTime.parse(startDateRaw ?? DateTime.now().toIso8601String()),
      checkOutDate: DateTime.parse(endDateRaw ?? DateTime.now().toIso8601String()),
      status: _mapStatus(statusRaw),
      paymentRequired: true,
      isPaid: isPaid,
      paymentStatus: paymentStatusRaw == null ? null : _mapPaymentStatus(paymentStatusRaw),
      totalPriceUzs: totalPrice,
      guestsCount: payload['guests_count'] is int ? payload['guests_count'] as int : 1,
      isReviewAllowed: _computeReviewAllowed(endDateRaw),
    );
  }

  BookingStatus _mapStatus(String? statusRaw) {
    switch (statusRaw) {
      case 'pending':
        return BookingStatus.pendingHostApproval;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelledByGuest;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pendingHostApproval;
    }
  }

  PaymentStatus _mapPaymentStatus(String raw) {
    final normalized = raw.toLowerCase().trim();
    for (final status in PaymentStatus.values) {
      if (status.name == normalized) {
        return status;
      }
    }
    return PaymentStatus.pending;
  }

  bool _computeReviewAllowed(String? endDateRaw) {
    if (endDateRaw == null || endDateRaw.isEmpty) {
      return false;
    }
    final endDate = DateTime.tryParse(endDateRaw);
    if (endDate == null) {
      return false;
    }
    final today = DateTime.now();
    final nowDate = DateTime(today.year, today.month, today.day);
    final stayEnd = DateTime(endDate.year, endDate.month, endDate.day);
    return !stayEnd.isAfter(nowDate);
  }

  Never _throwFailure(Failure failure) {
    throw AppException(
      failure.message,
      code: failure.code,
      statusCode: failure.statusCode,
    );
  }
}
