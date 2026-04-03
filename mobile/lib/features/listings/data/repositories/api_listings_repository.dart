import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
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

    if (result is ApiFailure<Map<String, dynamic>>) {
      _throwFailure(result.failure);
    }

    final data = (result as ApiSuccess<Map<String, dynamic>>).data;
    final items = await _canonicalizeListings(
      ApiResponseParser.extractList(
        data,
      ).map(_mapListing).toList(growable: false),
    );
    return _applyClientFilters(items, params: params);
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
  Future<List<Listing>> getMine({bool includeInactive = false}) async {
    final result = await _apiClient.get(
      ApiEndpoints.listings,
      queryParameters: const <String, dynamic>{'mine': 1},
    );

    if (result is ApiFailure<Map<String, dynamic>>) {
      _throwFailure(result.failure);
    }

    final data = (result as ApiSuccess<Map<String, dynamic>>).data;
    return _canonicalizeListings(
      ApiResponseParser.extractList(data)
          .map(_mapListing)
          .where((listing) => includeInactive || listing.isActive)
          .toList(growable: false),
    );
  }

  @override
  Future<List<Listing>> getByHost({
    required String hostId,
    required bool hasPremium,
    bool includeInactive = false,
  }) async {
    final result = await _apiClient.get(
      ApiEndpoints.listings,
      queryParameters: <String, dynamic>{'host': hostId},
    );

    if (result is ApiFailure<Map<String, dynamic>>) {
      _throwFailure(result.failure);
    }

    final data = (result as ApiSuccess<Map<String, dynamic>>).data;
    return _canonicalizeListings(
      ApiResponseParser.extractList(data)
          .map(_mapListing)
          .where((listing) => includeInactive || listing.isActive)
          .where(
            (listing) =>
                includeInactive ||
                hasPremium ||
                listing.type != ListingType.freeStay,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Listing> createListing(CreateListingInput input) async {
    final formData = await _buildListingFormData(input);
    final result = await _apiClient.post(ApiEndpoints.listings, data: formData);

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
    final formData = await _buildListingFormData(input);
    final result = await _apiClient.put(
      ApiEndpoints.listingManage(listingId),
      data: formData,
    );

    return result.when(
      success: (data) => _mapListing(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  @override
  Future<void> deleteListing(String listingId) async {
    final result = await _apiClient.delete(
      ApiEndpoints.listingManage(listingId),
    );
    result.when(success: (_) => null, failure: _throwFailure);
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

  Future<List<Listing>> _canonicalizeListings(List<Listing> items) async {
    if (items.isEmpty) {
      return const <Listing>[];
    }

    final resolved = await Future.wait(
      items.map((listing) async {
        if (!_needsCanonicalHydration(listing)) {
          return listing;
        }
        final fresh = await getById(listing.id);
        return fresh ?? listing;
      }),
    );

    return resolved
        .where((listing) => listing.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  bool _needsCanonicalHydration(Listing listing) {
    return listing.id.trim().isNotEmpty &&
        (listing.title.trim().isEmpty ||
            listing.city.trim().isEmpty ||
            listing.district.trim().isEmpty);
  }

  Future<FormData> _buildListingFormData(CreateListingInput input) async {
    final mapCoordinates = (input.mapCoordinates ?? '').trim();
    final parsedCoordinates = _parseCoordinates(mapCoordinates);
    final locationParts = <String>[
      input.city.trim(),
      input.district.trim(),
      if (mapCoordinates.isNotEmpty) mapCoordinates,
    ];
    final composedLocation = locationParts
        .where((part) => part.isNotEmpty)
        .join(', ');
    final normalizedLandmark = (input.landmark ?? '').trim();

    final data = <String, dynamic>{
      'title': input.title.trim(),
      'description': input.description.trim(),
      'city': input.city.trim(),
      'district': input.district.trim(),
      'location': composedLocation,
      if (parsedCoordinates != null) 'latitude': parsedCoordinates.$1,
      if (parsedCoordinates != null) 'longitude': parsedCoordinates.$2,
      if (normalizedLandmark.isNotEmpty || mapCoordinates.isNotEmpty)
        'landmark': normalizedLandmark.isNotEmpty
            ? normalizedLandmark
            : mapCoordinates,
      if ((input.metro ?? '').trim().isNotEmpty) 'metro': input.metro!.trim(),
      'listing_type': _mapTypeToApi(input.type),
      'amenities': input.amenities
          .map(_mapAmenityToApi)
          .toList(growable: false),
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
    };

    if (input.imageFiles.isNotEmpty) {
      data['image_files'] = await Future.wait(
        input.imageFiles.map((file) async {
          final bytes = await file.readAsBytes();
          final fileName = _normalizeImageFileName(file.name);
          return MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: _contentTypeForFileName(fileName),
          );
        }),
      );
    }
    final formData = FormData.fromMap(data);
    for (final value in input.removeImageUrls) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        continue;
      }
      formData.fields.add(MapEntry('remove_image_urls', normalized));
    }

    return formData;
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
        : '';
    final district =
        (payload['district']?.toString().trim().isNotEmpty ?? false)
        ? payload['district']!.toString().trim()
        : split.length > 1 && split[1].isNotEmpty
        ? split[1]
        : '';
    final rawType = payload['listing_type']?.toString().toLowerCase().trim();
    final rawPrice = payload['price_per_night'];
    final price = rawPrice is num
        ? rawPrice.toInt()
        : double.tryParse(rawPrice?.toString() ?? '')?.round();
    final images = _extractImageUrls(payload);
    final resolvedType = _mapTypeFromApi(rawType);
    final resolvedImages = images.isEmpty
        ? _fallbackAssetImages(title: payload['title']?.toString() ?? '')
        : images;
    final resolvedAmenities =
        _mapAmenitiesFromApi(payload['amenities']).takeIfNotEmpty() ??
        _fallbackAmenities(
          title: payload['title']?.toString() ?? '',
          type: resolvedType,
        );
    final landmarkRaw = payload['landmark']?.toString().trim();
    final payloadCoordinates = _extractCoordinatesFromPayload(payload);
    final derivedCoordinates = _extractCoordinatesFromLocation(location);

    return Listing(
      id: id,
      hostId: hostId,
      hostName: payload['host_name']?.toString().trim(),
      hostPhone: payload['host_phone']?.toString().trim(),
      title: payload['title']?.toString().trim() ?? '',
      city: city,
      district: district,
      type: resolvedType,
      maxGuests: _parseInt(payload['max_guests']) ?? 1,
      minDays: _parseInt(payload['min_days']) ?? 1,
      maxDays: _parseInt(payload['max_days']) ?? 30,
      nightlyPriceUzs: price,
      isActive: payload['is_active'] != false,
      amenities: resolvedAmenities,
      imageUrls: resolvedImages,
      description: payload['description']?.toString(),
      landmark: (landmarkRaw?.isNotEmpty ?? false)
          ? landmarkRaw
          : payloadCoordinates ?? derivedCoordinates,
      metro: payload['metro']?.toString(),
    );
  }

  List<String> _fallbackAssetImages({required String title}) {
    final normalizedTitle = title.toLowerCase().trim();
    if (normalizedTitle == 'cozy apartment near tashkent metro') {
      return const <String>[
        'assets/images/home1.png',
        'assets/images/home2.png',
        'assets/images/home4.png',
      ];
    }
    if (normalizedTitle == 'modern loft in city center') {
      return const <String>[
        'assets/images/home2.png',
        'assets/images/home3.png',
        'assets/images/home1.png',
      ];
    }
    if (normalizedTitle == 'family apartment near magic city') {
      return const <String>[
        'assets/images/home4.png',
        'assets/images/home1.png',
        'assets/images/home2.png',
      ];
    }
    if (normalizedTitle == 'quiet room with balcony in central tashkent') {
      return const <String>[
        'assets/images/home3.png',
        'assets/images/home2.png',
      ];
    }
    return const <String>[];
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

  List<ListingAmenity> _mapAmenitiesFromApi(Object? raw) {
    if (raw is! List) {
      return const <ListingAmenity>[];
    }
    final items = <ListingAmenity>[];
    for (final value in raw) {
      final amenity = _mapAmenityFromApi(value?.toString() ?? '');
      if (amenity != null && !items.contains(amenity)) {
        items.add(amenity);
      }
    }
    return items;
  }

  List<String> _extractImageUrls(Map<String, dynamic> payload) {
    final urls = <String>[];

    void addCandidate(Object? value) {
      final normalized = _normalizeImageUrl(value?.toString() ?? '');
      if (normalized.isNotEmpty && !urls.contains(normalized)) {
        urls.add(normalized);
      }
    }

    void addFromDynamic(Object? raw) {
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            addCandidate(_pickImageValue(item));
          } else {
            addCandidate(item);
          }
        }
        return;
      }
      if (raw is Map) {
        addCandidate(_pickImageValue(raw));
        return;
      }
      addCandidate(raw);
    }

    addFromDynamic(payload['images']);
    if (urls.isNotEmpty) {
      return urls;
    }

    const aliases = <String>['image_urls', 'imageUrls', 'photos', 'photo_urls'];
    for (final key in aliases) {
      addFromDynamic(payload[key]);
      if (urls.isNotEmpty) {
        break;
      }
    }
    return urls;
  }

  Object? _pickImageValue(Map<dynamic, dynamic> payload) {
    const keys = <String>['image', 'image_url', 'url', 'src', 'file'];
    for (final key in keys) {
      final value = payload[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _normalizeImageUrl(String raw) {
    final value = _restoreEncodedPercents(raw.trim());
    if (value.isEmpty) {
      return '';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      final baseUri = Uri.tryParse(_apiClient.baseUrl);
      if (uri == null || baseUri == null) {
        return value;
      }
      final localHosts = <String>{'127.0.0.1', 'localhost'};
      if (!uri.hasPort &&
          localHosts.contains(uri.host) &&
          baseUri.hasPort &&
          localHosts.contains(baseUri.host)) {
        return _encodeUrlIfNeeded(
          uri
              .replace(
                scheme: baseUri.scheme,
                host: baseUri.host,
                port: baseUri.port,
              )
              .toString(),
        );
      }
      return _encodeUrlIfNeeded(value);
    }

    final base = _apiClient.baseUrl;
    final apiIndex = base.indexOf('/api');
    final origin = apiIndex > 0 ? base.substring(0, apiIndex) : base;

    String relativePath = value;
    if (!relativePath.startsWith('/')) {
      relativePath = '/$relativePath';
    }
    if (!relativePath.startsWith('/media/')) {
      relativePath =
          '/media${relativePath.startsWith('/') ? '' : '/'}${relativePath.replaceFirst(RegExp(r'^/+'), '')}';
      relativePath = '/${relativePath.replaceFirst(RegExp(r'^/+'), '')}';
    }

    return _encodeUrlIfNeeded('$origin$relativePath');
  }

  String _restoreEncodedPercents(String value) {
    if (!value.contains('%25')) {
      return value;
    }
    return value.replaceAll('%25', '%');
  }

  String _encodeUrlIfNeeded(String value) {
    if (value.contains('%')) {
      return value;
    }
    return Uri.encodeFull(value);
  }

  (double, double)? _parseCoordinates(String value) {
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) {
      return null;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }
    return (lat, lng);
  }

  int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  MediaType _contentTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (lower.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    if (lower.endsWith('.bmp')) {
      return MediaType('image', 'bmp');
    }
    if (lower.endsWith('.avif')) {
      return MediaType('image', 'avif');
    }
    if (lower.endsWith('.heic')) {
      return MediaType('image', 'heic');
    }
    if (lower.endsWith('.heif')) {
      return MediaType('image', 'heif');
    }
    if (lower.endsWith('.tif') || lower.endsWith('.tiff')) {
      return MediaType('image', 'tiff');
    }
    return MediaType('image', 'jpeg');
  }

  String _normalizeImageFileName(String originalName) {
    final trimmed = originalName.trim();
    if (trimmed.isEmpty) {
      return 'listing_photo.jpg';
    }
    if (trimmed.contains('.')) {
      return trimmed;
    }
    return '$trimmed.jpg';
  }

  String? _extractCoordinatesFromLocation(String location) {
    final match = RegExp(
      r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)',
    ).firstMatch(location);
    if (match == null) {
      return null;
    }
    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) {
      return null;
    }
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  String? _extractCoordinatesFromPayload(Map<String, dynamic> payload) {
    final lat = double.tryParse(payload['latitude']?.toString() ?? '');
    final lng = double.tryParse(payload['longitude']?.toString() ?? '');
    if (lat == null || lng == null) {
      return null;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
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

  ListingAmenity? _mapAmenityFromApi(String value) {
    switch (value.trim()) {
      case 'wifi':
        return ListingAmenity.wifi;
      case 'airConditioner':
        return ListingAmenity.airConditioner;
      case 'kitchen':
        return ListingAmenity.kitchen;
      case 'washingMachine':
        return ListingAmenity.washingMachine;
      case 'parking':
        return ListingAmenity.parking;
      case 'privateBathroom':
        return ListingAmenity.privateBathroom;
      case 'kidsAllowed':
        return ListingAmenity.kidsAllowed;
      case 'petsAllowed':
        return ListingAmenity.petsAllowed;
      case 'womenOnly':
        return ListingAmenity.womenOnly;
      case 'menOnly':
        return ListingAmenity.menOnly;
      case 'hostLivesTogether':
        return ListingAmenity.hostLivesTogether;
      case 'instantConfirm':
        return ListingAmenity.instantConfirm;
      default:
        return null;
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

  String _mapAmenityToApi(ListingAmenity amenity) {
    switch (amenity) {
      case ListingAmenity.wifi:
        return 'wifi';
      case ListingAmenity.airConditioner:
        return 'airConditioner';
      case ListingAmenity.kitchen:
        return 'kitchen';
      case ListingAmenity.washingMachine:
        return 'washingMachine';
      case ListingAmenity.parking:
        return 'parking';
      case ListingAmenity.privateBathroom:
        return 'privateBathroom';
      case ListingAmenity.kidsAllowed:
        return 'kidsAllowed';
      case ListingAmenity.petsAllowed:
        return 'petsAllowed';
      case ListingAmenity.womenOnly:
        return 'womenOnly';
      case ListingAmenity.menOnly:
        return 'menOnly';
      case ListingAmenity.hostLivesTogether:
        return 'hostLivesTogether';
      case ListingAmenity.instantConfirm:
        return 'instantConfirm';
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

extension on List<ListingAmenity> {
  List<ListingAmenity>? takeIfNotEmpty() => isEmpty ? null : this;
}
