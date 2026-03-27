import '../../../../core/errors/app_exception.dart';
import '../../domain/models/availability_day.dart';
import '../../domain/models/create_listing_input.dart';
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
  static final Map<String, Map<DateTime, AvailabilityDay>> _availabilityByListing =
      <String, Map<DateTime, AvailabilityDay>>{};

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
    final cityToken = city.split(',').first.trim();
    final district = params.district.trim().toLowerCase();

    return _seed
        .where((listing) {
          if (!listing.isActive) {
            return false;
          }

          if (!params.includeFreeStay && listing.type == ListingType.freeStay) {
            return false;
          }

          final listingCity = listing.city.toLowerCase();
          if (cityToken.isNotEmpty &&
              !listingCity.contains(cityToken) &&
              !listing.title.toLowerCase().contains(cityToken) &&
              !(listing.landmark?.toLowerCase().contains(cityToken) ?? false) &&
              !(listing.metro?.toLowerCase().contains(cityToken) ?? false)) {
            return false;
          }

          if (district.isNotEmpty &&
              !listing.district.toLowerCase().contains(district) &&
              !(listing.landmark?.toLowerCase().contains(district) ?? false) &&
              !(listing.metro?.toLowerCase().contains(district) ?? false)) {
            return false;
          }

          if (params.guests > listing.maxGuests) {
            return false;
          }

          if (params.types.isNotEmpty && !params.types.contains(listing.type)) {
            return false;
          }

          if (params.amenities.isNotEmpty &&
              !params.amenities.every(listing.amenities.contains)) {
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

  @override
  Future<Listing> createListing(CreateListingInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return Listing(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      hostId: 'local_host',
      title: input.title.trim(),
      city: input.city.trim(),
      district: input.district.trim(),
      type: input.type,
      maxGuests: input.maxGuests,
      minDays: input.minDays,
      maxDays: input.maxDays,
      nightlyPriceUzs: input.type == ListingType.freeStay
          ? null
          : (input.nightlyPriceUzs ?? 0),
      isActive: true,
      description: input.description.trim(),
      landmark: input.landmark?.trim(),
      metro: input.metro?.trim(),
    );
  }

  @override
  Future<Listing> updateListing({
    required String listingId,
    required CreateListingInput input,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return Listing(
      id: listingId,
      hostId: 'local_host',
      title: input.title.trim(),
      city: input.city.trim(),
      district: input.district.trim(),
      type: input.type,
      maxGuests: input.maxGuests,
      minDays: input.minDays,
      maxDays: input.maxDays,
      nightlyPriceUzs: input.type == ListingType.freeStay
          ? null
          : (input.nightlyPriceUzs ?? 0),
      isActive: true,
      description: input.description.trim(),
      landmark: input.landmark?.trim(),
      metro: input.metro?.trim(),
    );
  }

  @override
  Future<List<AvailabilityDay>> getAvailability(String listingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final data = _availabilityByListing[listingId];
    if (data == null) {
      return const <AvailabilityDay>[];
    }
    final result = data.values.toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Future<List<AvailabilityDay>> upsertAvailability({
    required String listingId,
    required List<AvailabilityDay> days,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final map = _availabilityByListing.putIfAbsent(
      listingId,
      () => <DateTime, AvailabilityDay>{},
    );
    for (final day in days) {
      final key = DateTime(day.date.year, day.date.month, day.date.day);
      map[key] = AvailabilityDay(
        date: key,
        isAvailable: day.isAvailable,
        note: day.note,
      );
    }
    final result = map.values.toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}
