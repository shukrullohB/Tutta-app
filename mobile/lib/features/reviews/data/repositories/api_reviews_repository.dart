import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../domain/models/review.dart';
import '../../domain/repositories/reviews_repository.dart';

class ApiReviewsRepository implements ReviewsRepository {
  const ApiReviewsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Review> submitReview({
    required String bookingId,
    required String listingId,
    required String reviewerUserId,
    required String hostUserId,
    required int rating,
    required String comment,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.reviews,
      data: <String, dynamic>{
        'booking': int.tryParse(bookingId) ?? bookingId,
        'listing': int.tryParse(listingId) ?? listingId,
        'rating': rating,
        'comment': comment,
      },
    );

    return result.when(
      success: (data) => _mapReview(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  @override
  Future<List<Review>> getByListing(String listingId) async {
    final result = await _apiClient.get(
      ApiEndpoints.reviewsByListing(listingId),
    );

    return result.when(
      success: (data) => ApiResponseParser.extractList(
        data,
      ).map(_mapReview).toList(growable: false),
      failure: _throwFailure,
    );
  }

  Review _mapReview(Map<String, dynamic> payload) {
    return Review(
      id: payload['id'].toString(),
      bookingId: payload['booking']?.toString() ?? '',
      listingId: payload['listing']?.toString() ?? '',
      reviewerUserId: payload['guest_id']?.toString() ?? '',
      hostUserId: payload['host_id']?.toString() ?? '',
      rating: payload['rating'] is int
          ? payload['rating'] as int
          : int.tryParse(payload['rating']?.toString() ?? '') ?? 0,
      comment: payload['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(payload['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Never _throwFailure(Failure failure) {
    throw AppException(
      failure.message,
      code: failure.code,
      statusCode: failure.statusCode,
    );
  }
}
