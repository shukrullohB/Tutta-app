import '../models/booking.dart';
import '../../../payments/domain/models/payment_status.dart';

abstract interface class BookingRepository {
  Future<Booking?> getById(String bookingId);

  Future<Booking> createBookingRequest({
    required String listingId,
    required String guestUserId,
    required String hostUserId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required int totalPriceUzs,
  });

  Future<List<Booking>> getGuestBookings(String guestUserId);

  Future<List<Booking>> getHostBookings(String hostUserId);

  Future<Booking> confirmBooking({
    required String bookingId,
    required String hostUserId,
  });

  Future<Booking> rejectBooking({
    required String bookingId,
    required String hostUserId,
  });

  Future<Booking> cancelByGuest({
    required String bookingId,
    required String guestUserId,
  });

  Future<Booking> markCompleted({
    required String bookingId,
    required String hostUserId,
  });

  Future<Booking> setPaymentStatus({
    required String bookingId,
    required String guestUserId,
    required PaymentStatus paymentStatus,
  });
}
