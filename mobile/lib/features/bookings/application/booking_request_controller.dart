import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';
import '../data/repositories/api_booking_repository.dart';
import '../data/repositories/fake_booking_repository.dart';
import '../domain/models/booking.dart';
import '../domain/repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  if (!RuntimeFlags.useFakeBookings) {
    return ApiBookingRepository(ref.watch(apiClientProvider));
  }

  return FakeBookingRepository();
});

class BookingRequestController extends StateNotifier<AsyncValue<void>> {
  BookingRequestController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  Future<Booking> createRequest({
    required String listingId,
    required String hostUserId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required int totalPriceUzs,
  }) async {
    state = const AsyncValue.loading();

    final auth = _read.read(authControllerProvider).valueOrNull;
    final userId = auth?.user?.id;

    if (userId == null) {
      state = AsyncValue.error(
        const AppException('Please sign in again.'),
        StackTrace.current,
      );
      throw const AppException('Please sign in again.');
    }

    try {
      final booking = await _read
          .read(bookingRepositoryProvider)
          .createBookingRequest(
            listingId: listingId,
            guestUserId: userId,
            hostUserId: hostUserId,
            checkIn: checkIn,
            checkOut: checkOut,
            guests: guests,
            totalPriceUzs: totalPriceUzs,
          );

      state = const AsyncValue.data(null);
      return booking;
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final appError = AppException(error.toString());
      state = AsyncValue.error(appError, stackTrace);
      throw appError;
    }
  }
}

final bookingRequestControllerProvider =
    StateNotifierProvider<BookingRequestController, AsyncValue<void>>((ref) {
      return BookingRequestController(ref);
    });
