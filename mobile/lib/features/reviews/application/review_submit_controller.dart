import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../bookings/application/booking_request_controller.dart';
import '../../bookings/domain/models/booking.dart';
import '../data/repositories/api_reviews_repository.dart';
import '../data/repositories/fake_reviews_repository.dart';
import '../domain/repositories/reviews_repository.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  if (!RuntimeFlags.useFakeReviews) {
    return ApiReviewsRepository(ref.watch(apiClientProvider));
  }

  return FakeReviewsRepository();
});

class ReviewSubmitController extends StateNotifier<AsyncValue<void>> {
  ReviewSubmitController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  Future<void> submit({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    state = const AsyncValue.loading();

    final userId = _read.read(authControllerProvider).valueOrNull?.user?.id;
    if (userId == null) {
      state = AsyncValue.error(
        const AppException('Please sign in again.'),
        StackTrace.current,
      );
      throw const AppException('Please sign in again.');
    }

    final booking = await _read
        .read(bookingRepositoryProvider)
        .getById(bookingId);
    if (booking == null) {
      state = AsyncValue.error(
        const AppException('Booking not found.'),
        StackTrace.current,
      );
      throw const AppException('Booking not found.');
    }

    if (booking.guestUserId != userId) {
      state = AsyncValue.error(
        const AppException('Only guest can submit this review.'),
        StackTrace.current,
      );
      throw const AppException('Only guest can submit this review.');
    }

    if (booking.status != BookingStatus.confirmed || !booking.isReviewAllowed) {
      state = AsyncValue.error(
        const AppException('Review is allowed only after checkout date.'),
        StackTrace.current,
      );
      throw const AppException('Review is allowed only after checkout date.');
    }

    try {
      await _read
          .read(reviewsRepositoryProvider)
          .submitReview(
            bookingId: booking.id,
            listingId: booking.listingId,
            reviewerUserId: userId,
            hostUserId: booking.hostUserId,
            rating: rating,
            comment: comment,
          );
      state = const AsyncValue.data(null);
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

final reviewSubmitControllerProvider =
    StateNotifierProvider<ReviewSubmitController, AsyncValue<void>>((ref) {
      return ReviewSubmitController(ref);
    });
