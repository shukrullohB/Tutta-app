import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../domain/models/availability_day.dart';
import '../../domain/models/create_listing_input.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/listing_search_params.dart';
import '../../domain/repositories/listings_repository.dart';

class ApiListingsRepository implements ListingsRepository {
  const ApiListingsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Listing>> search({
    required ListingSearchParams params,
    required bool hasPremium,
  }) async {
    if (params.includeFreeStay && !hasPremium) {
      throw const AppException(
        'Free Stay search is available only for Premium users.',
      );
    }

    final normalizedCity = params.city.split(',').first.trim();
    final normalizedDistrict = params.district.trim();

    final result = await _apiClient.get(
      ApiEndpoints.listings,
      queryParameters: <String, dynamic>{
        if (normalizedCity.isNotEmpty) 'city': normalizedCity,
        if (normalizedDistrict.isNotEmpty) 'district': normalizedDistrict,
        'guests': params.guests,
        if (params.minPriceUzs != null) 'min_price': params.minPriceUzs,
        if (params.maxPriceUzs != null) 'max_price': params.maxPriceUzs,
        if (params.types.length == 1) 'type': _mapTypeToApi(params.types.first),
      },
    );

    return result.when(
      success: (data) {
        final items = ApiResponseParser.extractList(data).map(_mapListing);
        return _applyClientFilters(
          items.toList(growable: false),
          params: params,
        );
      },
      failure: _throwFailure,
    );
  }

  @override
  Future<Listing?> getById(String listingId) async {
    final result = await _apiClient.get(ApiEndpoints.listingById(listingId));

    return result.when(
      success: (data) => _mapListing(ApiResponseParser.extractMap(data)),
      failure: (failure) {
        if (failure.statusCode == 404) {
          return null;
        }
        _throwFailure(failure);
      },
    );
  }

  @override
  Future<List<Listing>> getByHost({
    required String hostId,
    required bool hasPremium,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.listings,
      queryParameters: <String, dynamic>{'host': hostId},
    );

    return result.when(
      success: (data) {
        final items = ApiResponseParser.extractList(data)
            .map(_mapListing)
            .where((listing) => listing.isActive)
            .where((listing) => hasPremium || listing.type != ListingType.freeStay)
            .toList(growable: false);
        return items;
      },
      failure: _throwFailure,
    );
  }

  @override
  Future<Listing> createListing(CreateListingInput input) async {
    final result = await _apiClient.post(
      ApiEndpoints.listings,
      data: <String, dynamic>{
        'title': input.title.trim(),
        'description': input.description.trim(),
        'city': input.city.trim(),
        'district': input.district.trim(),
        'location': '${input.city.trim()}, ${input.district.trim()}',
        if ((input.landmark ?? '').trim().isNotEmpty)
          'landmark': input.landmark!.trim(),
        if ((input.metro ?? '').trim().isNotEmpty) 'metro': input.metro!.trim(),
        'listing_type': _mapTypeToApi(input.type),
        'price_per_night': input.type == ListingType.freeStay
            ? null
            : input.nightlyPriceUzs,
        'max_guests': input.maxGuests,
        'min_days': input.minDays,
        'max_days': input.maxDays,
        'show_phone': input.showPhone,
        'free_stay_profile': input.type == ListingType.freeStay
            ? input.freeStayProfile
            : <String, dynamic>{},
      },
    );

    return result.when(
      success: (data) => _mapListing(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  @override
  Future<Listing> updateListing({
    required String listingId,
    required CreateListingInput input,
  }) async {
    final result = await _apiClient.put(
      ApiEndpoints.listingManage(listingId),
      data: <String, dynamic>{
        'title': input.title.trim(),
        'description': input.description.trim(),
        'city': input.city.trim(),
        'district': input.district.trim(),
        'location': '${input.city.trim()}, ${input.district.trim()}',
        if ((input.landmark ?? '').trim().isNotEmpty)
          'landmark': input.landmark!.trim(),
        if ((input.metro ?? '').trim().isNotEmpty) 'metro': input.metro!.trim(),
        'listing_type': _mapTypeToApi(input.type),
        'price_per_night': input.type == ListingType.freeStay
            ? null
            : input.nightlyPriceUzs,
        'max_guests': input.maxGuests,
        'min_days': input.minDays,
        'max_days': input.maxDays,
        'show_phone': input.showPhone,
        'free_stay_profile': input.type == ListingType.freeStay
            ? input.freeStayProfile
            : <String, dynamic>{},
      },
    );

    return result.when(
      success: (data) => _mapListing(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  List<Listing> _applyClientFilters(
    List<Listing> source, {
    required ListingSearchParams params,
  }) {
    final city = params.city.split(',').first.trim().toLowerCase();
    final district = params.district.trim().toLowerCase();

    return source
        .where((listing) {
          if (!listing.isActive) {
            return false;
          }
          if (!params.includeFreeStay && listing.type == ListingType.freeStay) {
            return false;
          }
          if (city.isNotEmpty && !listing.city.toLowerCase().contains(city)) {
            return false;
          }
          if (district.isNotEmpty &&
              !listing.district.toLowerCase().contains(district)) {
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

  Listing _mapListing(Map<String, dynamic> payload) {
    final id = payload['id']?.toString() ?? '';
    final hostId = payload['host_id']?.toString() ?? '';
    final location = payload['location']?.toString() ?? '';
    final split = location.split(',').map((e) => e.trim()).toList();
    final city = (payload['city']?.toString().trim().isNotEmpty ?? false)
        ? payload['city']!.toString().trim()
        : split.isNotEmpty && split.first.isNotEmpty
        ? split.first
        : 'Unknown';
    final district =
        (payload['district']?.toString().trim().isNotEmpty ?? false)
        ? payload['district']!.toString().trim()
        : split.length > 1 && split[1].isNotEmpty
        ? split[1]
        : city;
    final rawType = payload['listing_type']?.toString().toLowerCase().trim();
    final rawPrice = payload['price_per_night'];
    final price = rawPrice is num
        ? rawPrice.toInt()
        : double.tryParse(rawPrice?.toString() ?? '')?.round();
    final images = (payload['images'] is List)
        ? (payload['images'] as List)
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return _normalizeImageUrl(item['image']?.toString() ?? '');
                }
                return _normalizeImageUrl(item?.toString() ?? '');
              })
              .where((url) => url.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    final resolvedType = _mapTypeFromApi(rawType);
    final resolvedImages = images.isEmpty
        ? _fallbackAssetImages(
            id: id,
            title: payload['title']?.toString() ?? '',
          )
        : images;
    final resolvedAmenities = _fallbackAmenities(
      title: payload['title']?.toString() ?? '',
      type: resolvedType,
    );

    return Listing(
      id: id,
      hostId: hostId,
      hostName: payload['host_name']?.toString().trim(),
      hostPhone: payload['host_phone']?.toString().trim(),
      title: payload['title']?.toString() ?? 'Listing',
      city: city,
      district: district,
      type: resolvedType,
      maxGuests: payload['max_guests'] is int
          ? payload['max_guests'] as int
          : 1,
      minDays: payload['min_days'] is int ? payload['min_days'] as int : 1,
      maxDays: payload['max_days'] is int ? payload['max_days'] as int : 30,
      nightlyPriceUzs: price,
      isActive: payload['is_active'] != false,
      amenities: resolvedAmenities,
      imageUrls: resolvedImages,
      description: payload['description']?.toString(),
      landmark: payload['landmark']?.toString(),
      metro: payload['metro']?.toString(),
    );
  }

  List<String> _fallbackAssetImages({
    required String id,
    required String title,
  }) {
    const all = <String>[
      'assets/images/home1.png',
      'assets/images/home2.png',
      'assets/images/home3.png',
      'assets/images/home4.png',
    ];

    final normalizedTitle = title.toLowerCase();
    if (normalizedTitle.contains('cozy')) {
      return const <String>[
        'assets/images/home1.png',
        'assets/images/home2.png',
        'assets/images/home4.png',
      ];
    }
    if (normalizedTitle.contains('loft')) {
      return const <String>[
        'assets/images/home2.png',
        'assets/images/home3.png',
        'assets/images/home1.png',
      ];
    }
    if (normalizedTitle.contains('family')) {
      return const <String>[
        'assets/images/home4.png',
        'assets/images/home1.png',
        'assets/images/home2.png',
      ];
    }
    if (normalizedTitle.contains('room')) {
      return const <String>[
        'assets/images/home3.png',
        'assets/images/home2.png',
      ];
    }

    final hash = id.codeUnits.fold<int>(0, (sum, item) => sum + item);
    final start = hash % all.length;
    return List<String>.generate(
      3,
      (index) => all[(start + index) % all.length],
      growable: false,
    );
  }

  List<ListingAmenity> _fallbackAmenities({
    required String title,
    required ListingType type,
  }) {
    final normalizedTitle = title.toLowerCase();
    final amenities = <ListingAmenity>{
      ListingAmenity.wifi,
      ListingAmenity.kitchen,
    };

    if (type == ListingType.apartment || type == ListingType.homePart) {
      amenities.addAll(<ListingAmenity>{
        ListingAmenity.airConditioner,
        ListingAmenity.washingMachine,
      });
    }

    if (normalizedTitle.contains('family')) {
      amenities.addAll(<ListingAmenity>{
        ListingAmenity.kidsAllowed,
        ListingAmenity.privateBathroom,
      });
    }

    if (normalizedTitle.contains('loft')) {
      amenities.add(ListingAmenity.instantConfirm);
    }

    if (normalizedTitle.contains('room')) {
      amenities.add(ListingAmenity.hostLivesTogether);
    }

    if (type == ListingType.room) {
      amenities.add(ListingAmenity.privateBathroom);
    }

    return amenities.toList(growable: false);
  }

  String _normalizeImageUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final base = _apiClient.baseUrl;
    final apiIndex = base.indexOf('/api');
    final origin = apiIndex > 0 ? base.substring(0, apiIndex) : base;

    if (value.startsWith('/')) {
      return '$origin$value';
    }
    return '$origin/$value';
  }

  ListingType _mapTypeFromApi(String? value) {
    switch (value) {
      case 'room':
        return ListingType.room;
      case 'home':
        return ListingType.apartment;
      case 'free_stay':
        return ListingType.freeStay;
      default:
        return ListingType.apartment;
    }
  }

  String _mapTypeToApi(ListingType type) {
    switch (type) {
      case ListingType.room:
        return 'room';
      case ListingType.homePart:
        return 'home';
      case ListingType.apartment:
        return 'home';
      case ListingType.freeStay:
        return 'free_stay';
    }
  }

  Never _throwFailure(Failure failure) {
    throw AppException(
      failure.message,
      code: failure.code,
      statusCode: failure.statusCode,
    );
  }

  @override
  Future<List<AvailabilityDay>> getAvailability(String listingId) async {
    final result = await _apiClient.get(
      ApiEndpoints.listingAvailability(listingId),
    );
    return result.when(
      success: (data) {
        final items = ApiResponseParser.extractList(data);
        return items
            .map(
              (item) => AvailabilityDay(
                date: DateTime.parse(item['date'].toString()),
                isAvailable: item['is_available'] == true,
                note: item['note']?.toString(),
              ),
            )
            .toList(growable: false);
      },
      failure: _throwFailure,
    );
  }

  @override
  Future<List<AvailabilityDay>> upsertAvailability({
    required String listingId,
    required List<AvailabilityDay> days,
  }) async {
    final result = await _apiClient.put(
      ApiEndpoints.listingAvailability(listingId),
      data: <String, dynamic>{
        'days': days
            .map(
              (day) => <String, dynamic>{
                'date': day.date.toIso8601String().split('T').first,
                'is_available': day.isAvailable,
                if ((day.note ?? '').trim().isNotEmpty)
                  'note': day.note!.trim(),
              },
            )
            .toList(growable: false),
      },
    );
    return result.when(
      success: (data) {
        final items = ApiResponseParser.extractList(data);
        return items
            .map(
              (item) => AvailabilityDay(
                date: DateTime.parse(item['date'].toString()),
                isAvailable: item['is_available'] == true,
                note: item['note']?.toString(),
              ),
            )
            .toList(growable: false);
      },
      failure: _throwFailure,
    );
  }
}
