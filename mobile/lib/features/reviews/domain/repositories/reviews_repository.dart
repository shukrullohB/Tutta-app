import '../models/review.dart';

abstract interface class ReviewsRepository {
  Future<Review> submitReview({
    required String bookingId,
    required String listingId,
    required String reviewerUserId,
    required String hostUserId,
    required int rating,
    required String comment,
  });

  Future<List<Review>> getByListing(String listingId);
}
