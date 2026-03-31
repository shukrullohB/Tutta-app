import '../../../../core/errors/app_exception.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/listing_search_params.dart';
import '../../domain/repositories/listings_repository.dart';

class FakeListingsRepository implements ListingsRepository {
  static const _seed = <Listing>[
    Listing(
      id: 'l1',
      hostId: 'h1',
      title: 'Cozy apartment near Tashkent Metro',
      city: 'Tashkent',
      district: 'Yunusabad',
      type: ListingType.apartment,
      maxGuests: 3,
      minDays: 1,
      maxDays: 30,
      nightlyPriceUzs: 420000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.airConditioner,
        ListingAmenity.kitchen,
        ListingAmenity.washingMachine,
        ListingAmenity.instantConfirm,
      ],
      landmark: 'Minor Mosque',
      metro: 'Minor',
      description: 'Modern apartment for short stays only.',
    ),
    Listing(
      id: 'l2',
      hostId: 'h2',
      title: 'Private room for women travelers',
      city: 'Tashkent',
      district: 'Mirzo Ulugbek',
      type: ListingType.room,
      maxGuests: 1,
      minDays: 2,
      maxDays: 15,
      nightlyPriceUzs: 260000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.womenOnly,
        ListingAmenity.hostLivesTogether,
      ],
      description: 'Safe and quiet room in family home.',
    ),
    Listing(
      id: 'l3',
      hostId: 'h3',
      title: 'Free Stay: Uzbek-English language exchange',
      city: 'Samarkand',
      district: 'Registan area',
      type: ListingType.freeStay,
      maxGuests: 1,
      minDays: 3,
      maxDays: 14,
      nightlyPriceUzs: null,
      isActive: true,
      amenities: [ListingAmenity.hostLivesTogether, ListingAmenity.kitchen],
      description: 'Practice English and Uzbek through cultural exchange.',
    ),
  ];

  @override
  Future<List<Listing>> search({
    required ListingSearchParams params,
    required bool hasPremium,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (params.includeFreeStay && !hasPremium) {
      throw const AppException(
        'Free Stay search is available only for Premium users.',
      );
    }

    final city = params.city.trim().toLowerCase();
    final district = params.district.trim().toLowerCase();

    return _seed
        .where((listing) {
          if (!listing.isActive) {
            return false;
          }

          if (!params.includeFreeStay && listing.type == ListingType.freeStay) {
            return false;
          }

          if (city.isNotEmpty && listing.city.toLowerCase() != city) {
            return false;
          }

          if (district.isNotEmpty &&
              !listing.district.toLowerCase().contains(district)) {
            return false;
          }

          if (params.guests > listing.maxGuests) {
            return false;
          }

          return true;
        })
        .toList(growable: false);
  }

  @override
  Future<Listing?> getById(String listingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    for (final listing in _seed) {
      if (listing.id == listingId) {
        return listing;
      }
    }
    return null;
  }
}
