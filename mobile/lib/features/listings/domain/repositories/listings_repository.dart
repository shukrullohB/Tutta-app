import '../models/create_listing_input.dart';
import '../models/availability_day.dart';
import '../models/listing.dart';
import '../models/listing_search_params.dart';

abstract interface class ListingsRepository {
  Future<List<Listing>> search({
    required ListingSearchParams params,
    required bool hasPremium,
  });

  Future<Listing?> getById(String listingId);

  Future<Listing> createListing(CreateListingInput input);

  Future<Listing> updateListing({
    required String listingId,
    required CreateListingInput input,
  });

  Future<List<AvailabilityDay>> getAvailability(String listingId);

  Future<List<AvailabilityDay>> upsertAvailability({
    required String listingId,
    required List<AvailabilityDay> days,
  });
}
