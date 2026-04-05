import '../../../../core/errors/app_exception.dart';
import '../../domain/models/review.dart';
import '../../domain/repositories/reviews_repository.dart';

class FakeReviewsRepository implements ReviewsRepository {
  final List<Review> _reviews = <Review>[
    Review(
      id: 'seed_review_1',
      bookingId: 'seed_completed_1',
      listingId: 'l1',
      reviewerUserId: 'guest_demo_2',
      reviewerName: 'Aziza Karimova',
      hostUserId: 'h1',
      rating: 5,
      comment: 'Great location and very clean apartment. Host was responsive.',
      createdAt: DateTime(2026, 2, 2),
    ),
    Review(
      id: 'seed_review_2',
      bookingId: 'seed_completed_2',
      listingId: 'l1',
      reviewerUserId: 'guest_demo_3',
      reviewerName: 'Dilshod Rakhimov',
      hostUserId: 'h1',
      rating: 4,
      comment: 'Comfortable stay, metro is really close.',
      createdAt: DateTime(2026, 2, 14),
    ),
    Review(
      id: 'seed_review_3',
      bookingId: 'seed_completed_3',
      listingId: 'l2',
      reviewerUserId: 'guest_demo_4',
      reviewerName: 'Madina Yuldasheva',
      hostUserId: 'h2',
      rating: 5,
      comment: 'Very safe and quiet place. Host was very kind.',
      createdAt: DateTime(2026, 1, 30),
    ),
    Review(
      id: 'seed_review_4',
      bookingId: 'seed_completed_4',
      listingId: 'l4',
      reviewerUserId: 'guest_demo_5',
      reviewerName: 'Kamola Ismoilova',
      hostUserId: 'h4',
      rating: 5,
      comment: 'Looks exactly like photos, stylish and clean.',
      createdAt: DateTime(2026, 2, 19),
    ),
    Review(
      id: 'seed_review_5',
      bookingId: 'seed_completed_5',
      listingId: 'l5',
      reviewerUserId: 'guest_demo_6',
      reviewerName: 'Jasur Akhmedov',
      hostUserId: 'h5',
      rating: 4,
      comment: 'Great for family stay, kitchen had everything needed.',
      createdAt: DateTime(2026, 2, 25),
    ),
  ];

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
      reviewerName: 'You',
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

    final direct = _reviews
        .where((review) => review.listingId == listingId)
        .toList(growable: false);
    if (direct.isNotEmpty) {
      return direct;
    }

    // Example listings use ids like `example_tashkent_mirobod_2`.
    // Return a realistic fallback instead of empty/error blocks.
    if (listingId.startsWith('example_')) {
      return <Review>[
        Review(
          id: 'example_${listingId}_r1',
          bookingId: 'example_${listingId}_b1',
          listingId: listingId,
          reviewerUserId: 'guest_demo_21',
          reviewerName: 'Akmal R.',
          hostUserId: 'host_demo',
          rating: 5,
          comment: 'Very clean, accurate photos, and smooth check-in.',
          createdAt: DateTime(2026, 3, 18),
        ),
        Review(
          id: 'example_${listingId}_r2',
          bookingId: 'example_${listingId}_b2',
          listingId: listingId,
          reviewerUserId: 'guest_demo_22',
          reviewerName: 'Nodira K.',
          hostUserId: 'host_demo',
          rating: 4,
          comment: 'Good location and responsive host. Would stay again.',
          createdAt: DateTime(2026, 3, 26),
        ),
      ];
    }

    return direct;
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _reviews.removeWhere((review) => review.id == reviewId);
  }
}
