import '../../../../core/errors/app_exception.dart';
import '../../domain/models/review.dart';
import '../../domain/repositories/reviews_repository.dart';

class FakeReviewsRepository implements ReviewsRepository {
  final List<Review> _reviews = <Review>[];

  @override
  Future<Review> submitReview({
    required String bookingId,
    required String listingId,
    required String reviewerUserId,
    required String hostUserId,
    required int rating,
    required String comment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (rating < 1 || rating > 5) {
      throw const AppException('Rating must be between 1 and 5.');
    }

    final duplicate = _reviews.any((review) => review.bookingId == bookingId);
    if (duplicate) {
      throw const AppException('Review is already submitted for this booking.');
    }

    final trimmedComment = comment.trim();
    if (trimmedComment.isEmpty) {
      throw const AppException('Please write a short review comment.');
    }

    final review = Review(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      listingId: listingId,
      reviewerUserId: reviewerUserId,
      hostUserId: hostUserId,
      rating: rating,
      comment: trimmedComment,
      createdAt: DateTime.now(),
    );

    _reviews.add(review);
    return review;
  }

  @override
  Future<List<Review>> getByListing(String listingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return _reviews
        .where((review) => review.listingId == listingId)
        .toList(growable: false);
  }
}
