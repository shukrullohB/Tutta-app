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

    final result = await _apiClient.get(
      ApiEndpoints.listings,
      queryParameters: <String, dynamic>{
        if (params.city.trim().isNotEmpty) 'city': params.city.trim(),
        if (params.city.trim().isNotEmpty) 'q': params.city.trim(),
        if (params.district.trim().isNotEmpty) 'district': params.district.trim(),
        'guests': params.guests,
        if (params.types.isNotEmpty)
          'type': _mapTypeToApi(params.types.first),
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
    final city = params.city.trim().toLowerCase();
    final district = params.district.trim().toLowerCase();

    return source.where((listing) {
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
      return true;
    }).toList(growable: false);
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
    final district = (payload['district']?.toString().trim().isNotEmpty ?? false)
        ? payload['district']!.toString().trim()
        : split.length > 1 && split[1].isNotEmpty
        ? split[1]
        : city;
    final rawType = payload['listing_type']?.toString().toLowerCase().trim();
    final rawPrice = payload['price_per_night'];
    final price = rawPrice is num
        ? rawPrice.toInt()
        : int.tryParse(rawPrice?.toString() ?? '');
    final images = (payload['images'] is List)
        ? (payload['images'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => item['image']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return Listing(
      id: id,
      hostId: hostId,
      title: payload['title']?.toString() ?? 'Listing',
      city: city,
      district: district,
      type: _mapTypeFromApi(rawType),
      maxGuests: payload['max_guests'] is int ? payload['max_guests'] as int : 1,
      minDays: payload['min_days'] is int ? payload['min_days'] as int : 1,
      maxDays: payload['max_days'] is int ? payload['max_days'] as int : 30,
      nightlyPriceUzs: price,
      isActive: payload['is_active'] == true,
      amenities: const <ListingAmenity>[],
      imageUrls: images,
      description: payload['description']?.toString(),
      landmark: payload['landmark']?.toString(),
      metro: payload['metro']?.toString(),
    );
  }

  ListingType _mapTypeFromApi(String? value) {
    switch (value) {
      case 'room':
        return ListingType.room;
      case 'home':
        return ListingType.homePart;
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
    final result = await _apiClient.get(ApiEndpoints.listingAvailability(listingId));
    return result.when(
      success: (data) {
        final items = ApiResponseParser.extractList(data);
        return items
            .map((item) => AvailabilityDay(
                  date: DateTime.parse(item['date'].toString()),
                  isAvailable: item['is_available'] == true,
                  note: item['note']?.toString(),
                ))
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
                if ((day.note ?? '').trim().isNotEmpty) 'note': day.note!.trim(),
              },
            )
            .toList(growable: false),
      },
    );
    return result.when(
      success: (data) {
        final items = ApiResponseParser.extractList(data);
        return items
            .map((item) => AvailabilityDay(
                  date: DateTime.parse(item['date'].toString()),
                  isAvailable: item['is_available'] == true,
                  note: item['note']?.toString(),
                ))
            .toList(growable: false);
      },
      failure: _throwFailure,
    );
  }
}
