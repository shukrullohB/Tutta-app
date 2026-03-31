import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../payments/domain/models/payment_status.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

enum BookingStatus {
  pendingHostApproval,
  confirmed,
  cancelledByGuest,
  cancelledByHost,
  completed,
}

@freezed
class Booking with _$Booking {
  const factory Booking({
    required String id,
    required String listingId,
    required String guestUserId,
    required String hostUserId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required BookingStatus status,
    required bool paymentRequired,
    required bool isPaid,
    PaymentStatus? paymentStatus,
    required int totalPriceUzs,
    required int guestsCount,
    required bool isReviewAllowed,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
}
