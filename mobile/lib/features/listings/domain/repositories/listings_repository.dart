import '../models/listing.dart';
import '../models/listing_search_params.dart';

abstract interface class ListingsRepository {
  Future<List<Listing>> search({
    required ListingSearchParams params,
    required bool hasPremium,
  });

  Future<Listing?> getById(String listingId);
}
