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
      imageUrls: [
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1493666438817-866a91353ca9?auto=format&fit=crop&w=1200&q=80',
      ],
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
      imageUrls: [
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l4',
      hostId: 'h4',
      title: 'Modern loft in City Center',
      city: 'Tashkent',
      district: 'Mirobod',
      type: ListingType.apartment,
      maxGuests: 2,
      minDays: 1,
      maxDays: 20,
      nightlyPriceUzs: 510000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.airConditioner,
        ListingAmenity.kitchen,
        ListingAmenity.privateBathroom,
      ],
      landmark: 'Tashkent City',
      metro: 'Kosmonavtlar',
      description: 'Bright loft with cozy interior and fast Wi-Fi.',
      imageUrls: [
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l5',
      hostId: 'h5',
      title: 'Family apartment near Magic City',
      city: 'Tashkent',
      district: 'Chilonzor',
      type: ListingType.apartment,
      maxGuests: 4,
      minDays: 2,
      maxDays: 30,
      nightlyPriceUzs: 690000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.kitchen,
        ListingAmenity.washingMachine,
        ListingAmenity.kidsAllowed,
      ],
      landmark: 'Magic City',
      description: 'Spacious apartment for family short stays.',
      imageUrls: [
        'https://images.unsplash.com/photo-1493666438817-866a91353ca9?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l6',
      hostId: 'h6',
      title: 'Compact studio close to metro',
      city: 'Tashkent',
      district: 'Shaykhontohur',
      type: ListingType.room,
      maxGuests: 2,
      minDays: 1,
      maxDays: 12,
      nightlyPriceUzs: 330000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.airConditioner,
        ListingAmenity.privateBathroom,
      ],
      metro: 'Paxtakor',
      description: 'Perfect for weekend trips and business visits.',
      imageUrls: [
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l7',
      hostId: 'h7',
      title: 'Minimal room in quiet district',
      city: 'Tashkent',
      district: 'Yakkasaray',
      type: ListingType.room,
      maxGuests: 1,
      minDays: 1,
      maxDays: 10,
      nightlyPriceUzs: 240000,
      isActive: true,
      amenities: [ListingAmenity.wifi, ListingAmenity.hostLivesTogether],
      description: 'Calm neighborhood and clean room.',
      imageUrls: [
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l8',
      hostId: 'h8',
      title: 'Part of home with private entrance',
      city: 'Tashkent',
      district: 'Yunusabad',
      type: ListingType.homePart,
      maxGuests: 3,
      minDays: 2,
      maxDays: 25,
      nightlyPriceUzs: 470000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.parking,
        ListingAmenity.kitchen,
      ],
      landmark: 'Minor',
      description: 'Independent entrance and flexible check-in.',
      imageUrls: [
        'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l9',
      hostId: 'h9',
      title: 'Business stay near central avenue',
      city: 'Tashkent',
      district: 'Mirzo Ulugbek',
      type: ListingType.apartment,
      maxGuests: 2,
      minDays: 1,
      maxDays: 14,
      nightlyPriceUzs: 560000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.airConditioner,
        ListingAmenity.washingMachine,
      ],
      description: 'Comfortable for business trips and short visits.',
      imageUrls: [
        'https://images.unsplash.com/photo-1464890100898-a385f744067f?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l10',
      hostId: 'h10',
      title: 'Quiet apartment for couples',
      city: 'Tashkent',
      district: 'Olmazor',
      type: ListingType.apartment,
      maxGuests: 2,
      minDays: 2,
      maxDays: 18,
      nightlyPriceUzs: 480000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.kitchen,
        ListingAmenity.petsAllowed,
      ],
      description: 'Quiet building with cozy interior.',
      imageUrls: [
        'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l11',
      hostId: 'h11',
      title: 'Free Stay: culture exchange in old mahalla',
      city: 'Tashkent',
      district: 'Shaykhontohur',
      type: ListingType.freeStay,
      maxGuests: 1,
      minDays: 3,
      maxDays: 14,
      nightlyPriceUzs: null,
      isActive: true,
      amenities: [ListingAmenity.hostLivesTogether, ListingAmenity.kitchen],
      description: 'Stay for free while practicing Uzbek and Russian.',
      imageUrls: [
        'https://images.unsplash.com/photo-1556911220-bda9f7f7597e?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l12',
      hostId: 'h12',
      title: 'Comfort studio with parking',
      city: 'Tashkent',
      district: 'Bektemir',
      type: ListingType.room,
      maxGuests: 2,
      minDays: 1,
      maxDays: 21,
      nightlyPriceUzs: 300000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.parking,
        ListingAmenity.kitchen,
      ],
      description: 'Affordable stay with free parking.',
      imageUrls: [
        'https://images.unsplash.com/photo-1502672023488-70e25813eb80?auto=format&fit=crop&w=1200&q=80',
      ],
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
      imageUrls: [
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    Listing(
      id: 'l13',
      hostId: 'h13',
      title: 'Old city apartment for short stays',
      city: 'Bukhara',
      district: 'Old City',
      type: ListingType.apartment,
      maxGuests: 3,
      minDays: 1,
      maxDays: 20,
      nightlyPriceUzs: 530000,
      isActive: true,
      amenities: [
        ListingAmenity.wifi,
        ListingAmenity.airConditioner,
        ListingAmenity.kitchen,
      ],
      landmark: 'Lyabi-Hauz',
      description: 'Historic area with modern comfort.',
      imageUrls: [
        'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
  ];
  static final List<Listing> _createdListings = <Listing>[];
  static final Map<String, Map<DateTime, AvailabilityDay>>
  _availabilityByListing = <String, Map<DateTime, AvailabilityDay>>{};

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

    return [..._seed, ..._createdListings]
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

          if (listing.nightlyPriceUzs != null) {
            if (params.minPriceUzs != null &&
                listing.nightlyPriceUzs! < params.minPriceUzs!) {
              return false;
            }
            if (params.maxPriceUzs != null &&
                listing.nightlyPriceUzs! > params.maxPriceUzs!) {
              return false;
            }
          } else if (params.minPriceUzs != null || params.maxPriceUzs != null) {
            return false;
          }

          return true;
        })
        .toList(growable: false);
  }

  @override
  Future<Listing?> getById(String listingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    for (final listing in [..._createdListings, ..._seed]) {
      if (listing.id == listingId) {
        return listing;
      }
    }
    return null;
  }

  @override
  Future<List<Listing>> getMine({bool includeInactive = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _createdListings
        .where((listing) => includeInactive || listing.isActive)
        .toList(growable: false);
  }

  @override
  Future<List<Listing>> getByHost({
    required String hostId,
    required bool hasPremium,
    bool includeInactive = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return [..._createdListings, ..._seed]
        .where((listing) => listing.hostId == hostId)
        .where((listing) => includeInactive || listing.isActive)
        .where(
          (listing) =>
              includeInactive ||
              hasPremium ||
              listing.type != ListingType.freeStay,
        )
        .toList(growable: false);
  }

  @override
  Future<Listing> createListing(CreateListingInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final listing = Listing(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      hostId: 'local_host',
      title: input.title.trim(),
      city: input.city.trim(),
      district: input.district.trim(),
      type: input.type,
      amenities: input.amenities,
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
    _createdListings.insert(0, listing);
    return listing;
  }

  @override
  Future<Listing> updateListing({
    required String listingId,
    required CreateListingInput input,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final listing = Listing(
      id: listingId,
      hostId: 'local_host',
      title: input.title.trim(),
      city: input.city.trim(),
      district: input.district.trim(),
      type: input.type,
      amenities: input.amenities,
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
    final index = _createdListings.indexWhere((item) => item.id == listingId);
    if (index >= 0) {
      _createdListings[index] = listing;
    }
    return listing;
  }

  @override
  Future<void> deleteListing(String listingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _createdListings.removeWhere((item) => item.id == listingId);
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
