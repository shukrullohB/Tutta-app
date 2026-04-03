import '../../../../core/errors/app_exception.dart';
import '../../domain/models/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../../payments/domain/models/payment_status.dart';

class FakeBookingRepository implements BookingRepository {
  final List<Booking> _bookings = <Booking>[
    Booking(
      id: 'seed_1',
      listingId: 'l1',
      guestUserId: 'user_demo_1',
      hostUserId: 'h1',
      checkInDate: DateTime(2026, 4, 5),
      checkOutDate: DateTime(2026, 4, 9),
      status: BookingStatus.pendingHostApproval,
      paymentRequired: true,
      isPaid: false,
      paymentStatus: null,
      totalPriceUzs: 1600000,
      guestsCount: 2,
      isReviewAllowed: false,
    ),
    Booking(
      id: 'seed_2',
      listingId: 'l2',
      guestUserId: 'user_demo_1',
      hostUserId: 'h2',
      checkInDate: DateTime(2026, 4, 14),
      checkOutDate: DateTime(2026, 4, 18),
      status: BookingStatus.confirmed,
      paymentRequired: true,
      isPaid: true,
      paymentStatus: PaymentStatus.succeeded,
      totalPriceUzs: 1040000,
      guestsCount: 1,
      isReviewAllowed: false,
    ),
    Booking(
      id: 'seed_3',
      listingId: 'l1',
      guestUserId: 'user_demo_1',
      hostUserId: 'h1',
      checkInDate: DateTime(2026, 2, 1),
      checkOutDate: DateTime(2026, 2, 5),
      status: BookingStatus.completed,
      paymentRequired: true,
      isPaid: true,
      paymentStatus: PaymentStatus.succeeded,
      totalPriceUzs: 1680000,
      guestsCount: 2,
      isReviewAllowed: true,
    ),
  ];

  @override
  Future<Booking?> getById(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    for (final booking in _bookings) {
      if (booking.id == bookingId) {
        return booking;
      }
    }
    return null;
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
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (guestUserId == hostUserId) {
      throw const AppException('You cannot book your own listing.');
    }

    final nights = checkOut.difference(checkIn).inDays;
    if (nights < 1) {
      throw const AppException('Check-out date must be after check-in date.');
    }

    if (nights > 30) {
      throw const AppException('Maximum booking length is 30 days.');
    }

    final hasOverlap = _bookings.any((booking) {
      if (booking.listingId != listingId) {
        return false;
      }

      if (booking.status == BookingStatus.cancelledByGuest ||
          booking.status == BookingStatus.cancelledByHost) {
        return false;
      }

      final startsBeforeOtherEnds = checkIn.isBefore(booking.checkOutDate);
      final endsAfterOtherStarts = checkOut.isAfter(booking.checkInDate);
      return startsBeforeOtherEnds && endsAfterOtherStarts;
    });

    if (hasOverlap) {
      throw const AppException(
        'Selected dates are no longer available for this listing.',
      );
    }

    final booking = Booking(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      listingId: listingId,
      guestUserId: guestUserId,
      hostUserId: hostUserId,
      checkInDate: checkIn,
      checkOutDate: checkOut,
      status: BookingStatus.pendingHostApproval,
      paymentRequired: totalPriceUzs > 0,
      isPaid: false,
      paymentStatus: null,
      totalPriceUzs: totalPriceUzs,
      guestsCount: guests,
      isReviewAllowed: false,
    );

    _bookings.add(booking);
    return booking;
  }

  @override
  Future<List<Booking>> getGuestBookings(String guestUserId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return _bookings
        .where((booking) => booking.guestUserId == guestUserId)
        .toList(growable: false);
  }

  @override
  Future<List<Booking>> getHostBookings(String hostUserId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return _bookings
        .where((booking) => booking.hostUserId == hostUserId)
        .toList(growable: false);
  }

  @override
  Future<Booking> confirmBooking({
    required String bookingId,
    required String hostUserId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _findIndex(bookingId);
    final booking = _bookings[index];

    if (booking.hostUserId != hostUserId) {
      throw const AppException('You are not allowed to confirm this booking.');
    }
    if (booking.status != BookingStatus.pendingHostApproval) {
      throw const AppException('Only pending requests can be confirmed.');
    }

    final updated = booking.copyWith(status: BookingStatus.confirmed);
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<Booking> rejectBooking({
    required String bookingId,
    required String hostUserId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _findIndex(bookingId);
    final booking = _bookings[index];

    if (booking.hostUserId != hostUserId) {
      throw const AppException('You are not allowed to reject this booking.');
    }
    if (booking.status != BookingStatus.pendingHostApproval) {
      throw const AppException('Only pending requests can be rejected.');
    }

    final updated = booking.copyWith(status: BookingStatus.cancelledByHost);
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<Booking> cancelByGuest({
    required String bookingId,
    required String guestUserId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _findIndex(bookingId);
    final booking = _bookings[index];

    if (booking.guestUserId != guestUserId) {
      throw const AppException('You are not allowed to cancel this booking.');
    }

    if (booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelledByGuest ||
        booking.status == BookingStatus.cancelledByHost) {
      throw const AppException('This booking cannot be cancelled.');
    }

    if (booking.status == BookingStatus.confirmed) {
      final now = DateTime.now();
      final hoursBeforeCheckIn = booking.checkInDate.difference(now).inHours;
      if (hoursBeforeCheckIn < 24) {
        throw const AppException(
          'Confirmed bookings can be cancelled only 24h before check-in.',
        );
      }
    }

    final updated = booking.copyWith(status: BookingStatus.cancelledByGuest);
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<Booking> markCompleted({
    required String bookingId,
    required String hostUserId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _findIndex(bookingId);
    final booking = _bookings[index];

    if (booking.hostUserId != hostUserId) {
      throw const AppException('You are not allowed to complete this booking.');
    }

    if (booking.status != BookingStatus.confirmed) {
      throw const AppException('Only confirmed bookings can be completed.');
    }

    final updated = booking.copyWith(
      status: BookingStatus.completed,
      isReviewAllowed: true,
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<Booking> setPaymentStatus({
    required String bookingId,
    required String guestUserId,
    required PaymentStatus paymentStatus,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _findIndex(bookingId);
    final booking = _bookings[index];

    if (booking.guestUserId != guestUserId) {
      throw const AppException('You are not allowed to update this payment.');
    }

    if (!booking.paymentRequired) {
      throw const AppException('Payment is not required for this booking.');
    }

    final paid = paymentStatus == PaymentStatus.succeeded;
    final updated = booking.copyWith(
      paymentStatus: paymentStatus,
      isPaid: paid,
    );
    _bookings[index] = updated;
    return updated;
  }

  int _findIndex(String bookingId) {
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) {
      throw const AppException('Booking was not found.');
    }
    return index;
  }
}
