import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../data/repositories/api_listings_repository.dart';
import '../data/repositories/fake_listings_repository.dart';
import '../domain/models/listing.dart';
import '../domain/models/listing_search_params.dart';
import '../domain/repositories/listings_repository.dart';

class SearchState {
  static const Object _unset = Object();

  const SearchState({
    required this.city,
    required this.district,
    required this.guests,
    required this.includeFreeStay,
    required this.minPriceUzs,
    required this.maxPriceUzs,
    required this.types,
    required this.amenities,
    required this.items,
    required this.errorMessage,
    required this.loading,
  });

  const SearchState.initial()
    : city = 'Tashkent',
      district = '',
      guests = 1,
      includeFreeStay = false,
      minPriceUzs = null,
      maxPriceUzs = null,
      types = const <ListingType>[],
      amenities = const <ListingAmenity>[],
      items = const <Listing>[],
      errorMessage = null,
      loading = false;

  final String city;
  final String district;
  final int guests;
  final bool includeFreeStay;
  final int? minPriceUzs;
  final int? maxPriceUzs;
  final List<ListingType> types;
  final List<ListingAmenity> amenities;
  final List<Listing> items;
  final String? errorMessage;
  final bool loading;

  SearchState copyWith({
    String? city,
    String? district,
    int? guests,
    bool? includeFreeStay,
    Object? minPriceUzs = _unset,
    Object? maxPriceUzs = _unset,
    List<ListingType>? types,
    List<ListingAmenity>? amenities,
    List<Listing>? items,
    String? errorMessage,
    bool clearError = false,
    bool? loading,
  }) {
    return SearchState(
      city: city ?? this.city,
      district: district ?? this.district,
      guests: guests ?? this.guests,
      includeFreeStay: includeFreeStay ?? this.includeFreeStay,
      minPriceUzs: minPriceUzs == _unset ? this.minPriceUzs : minPriceUzs as int?,
      maxPriceUzs: maxPriceUzs == _unset ? this.maxPriceUzs : maxPriceUzs as int?,
      types: types ?? this.types,
      amenities: amenities ?? this.amenities,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loading: loading ?? this.loading,
    );
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  if (!RuntimeFlags.useFakeListings) {
    return ApiListingsRepository(ref.watch(apiClientProvider));
  }
  return FakeListingsRepository();
});

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._read) : super(const SearchState.initial());

  final Ref _read;

  void setCity(String value) =>
      state = state.copyWith(city: value, clearError: true);

  void setDistrict(String value) =>
      state = state.copyWith(district: value, clearError: true);

  void setGuests(int value) =>
      state = state.copyWith(guests: value.clamp(1, 16), clearError: true);

  void setIncludeFreeStay(bool value) {
    state = state.copyWith(includeFreeStay: value, clearError: true);
  }

  void setTypes(List<ListingType> types) {
    state = state.copyWith(types: types, clearError: true);
  }

  void setAmenities(List<ListingAmenity> amenities) {
    state = state.copyWith(amenities: amenities, clearError: true);
  }

  void setPriceRange({int? minPriceUzs, int? maxPriceUzs}) {
    state = state.copyWith(
      minPriceUzs: minPriceUzs,
      maxPriceUzs: maxPriceUzs,
      clearError: true,
    );
  }

  Future<void> search() async {
    state = state.copyWith(loading: true, clearError: true);

    final auth = _read.read(authControllerProvider).valueOrNull;
    final hasPremium = auth?.user?.isPremium ?? false;

    try {
      final params = ListingSearchParams(
        city: state.city,
        district: state.district,
        guests: state.guests,
        includeFreeStay: state.includeFreeStay,
        minPriceUzs: state.minPriceUzs,
        maxPriceUzs: state.maxPriceUzs,
        types: state.types,
        amenities: state.amenities,
      );

      final items = await _read
          .read(listingsRepositoryProvider)
          .search(params: params, hasPremium: hasPremium);

      state = state.copyWith(items: items, loading: false, clearError: true);
    } on AppException catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Unable to search listings right now.',
      );
    }
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
      return SearchController(ref);
    });
