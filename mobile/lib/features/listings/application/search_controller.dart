import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../data/repositories/api_listings_repository.dart';
import '../data/repositories/fake_listings_repository.dart';
import '../domain/models/listing.dart';
import '../domain/models/example_listings.dart';
import '../domain/models/listing_search_params.dart';
import '../domain/repositories/listings_repository.dart';

enum HostListingsSyncState { idle, syncing, ok, warning }

class HostListingsSyncInfo {
  const HostListingsSyncInfo({required this.state, this.message});

  const HostListingsSyncInfo.idle()
    : state = HostListingsSyncState.idle,
      message = null;

  const HostListingsSyncInfo.syncing()
    : state = HostListingsSyncState.syncing,
      message = null;

  const HostListingsSyncInfo.ok()
    : state = HostListingsSyncState.ok,
      message = null;

  const HostListingsSyncInfo.warning(this.message)
    : state = HostListingsSyncState.warning;

  final HostListingsSyncState state;
  final String? message;
}

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
      minPriceUzs: minPriceUzs == _unset
          ? this.minPriceUzs
          : minPriceUzs as int?,
      maxPriceUzs: maxPriceUzs == _unset
          ? this.maxPriceUzs
          : maxPriceUzs as int?,
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

final locallyCreatedHostListingsProvider = StateProvider<List<Listing>>((ref) {
  return const <Listing>[];
});

final hostListingsSyncInfoProvider = StateProvider<HostListingsSyncInfo>((ref) {
  return const HostListingsSyncInfo.idle();
});

final hostOwnedListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull?.user;
  if (user == null) {
    return const <Listing>[];
  }

  final local = ref.watch(locallyCreatedHostListingsProvider);
  try {
    final remote = await ref
        .watch(listingsRepositoryProvider)
        .getMine(includeInactive: true);
    ref.read(hostListingsSyncInfoProvider.notifier).state =
        const HostListingsSyncInfo.ok();
    return mergeCreatedListings(remote: remote, local: local);
  } on AppException catch (error) {
    ref.read(hostListingsSyncInfoProvider.notifier).state =
        HostListingsSyncInfo.warning(error.message);
    if (local.isNotEmpty) {
      return local;
    }
    rethrow;
  } catch (error) {
    ref.read(hostListingsSyncInfoProvider.notifier).state =
        HostListingsSyncInfo.warning(error.toString());
    if (local.isNotEmpty) {
      return local;
    }
    rethrow;
  }
});

List<Listing> mergeCreatedListings({
  required List<Listing> remote,
  required List<Listing> local,
}) {
  final merged = <String, Listing>{for (final item in local) item.id: item};
  for (final item in remote) {
    final existing = merged[item.id];
    if (existing != null &&
        item.imageUrls.isEmpty &&
        existing.imageUrls.isNotEmpty) {
      merged[item.id] = item.copyWith(imageUrls: existing.imageUrls);
      continue;
    }
    merged[item.id] = item;
  }
  final items = merged.values.toList(growable: false);
  items.sort(
    (a, b) =>
        int.tryParse(b.id)?.compareTo(int.tryParse(a.id) ?? 0) ??
        b.id.compareTo(a.id),
  );
  return items;
}

bool matchesSearchParams(
  Listing listing,
  ListingSearchParams params, {
  required bool hasPremium,
}) {
  if (!listing.isActive) {
    return false;
  }
  if (!params.includeFreeStay && listing.type == ListingType.freeStay) {
    return false;
  }
  if (!hasPremium && listing.type == ListingType.freeStay) {
    return false;
  }

  final city = params.city.split(',').first.trim().toLowerCase();
  final district = params.district.trim().toLowerCase();

  if (city.isNotEmpty && !listing.city.toLowerCase().contains(city)) {
    return false;
  }
  if (district.isNotEmpty) {
    final landmark = (listing.landmark ?? '').toLowerCase();
    final metro = (listing.metro ?? '').toLowerCase();
    if (!listing.district.toLowerCase().contains(district) &&
        !landmark.contains(district) &&
        !metro.contains(district)) {
      return false;
    }
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
  final price = listing.nightlyPriceUzs;
  if (price != null) {
    if (params.minPriceUzs != null && price < params.minPriceUzs!) {
      return false;
    }
    if (params.maxPriceUzs != null && price > params.maxPriceUzs!) {
      return false;
    }
  } else if (params.minPriceUzs != null || params.maxPriceUzs != null) {
    return false;
  }
  return true;
}

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

    try {
      final items = await _read
          .read(listingsRepositoryProvider)
          .search(params: params, hasPremium: hasPremium);
      final localItems = _read.read(locallyCreatedHostListingsProvider);
      final merged = mergeCreatedListings(remote: items, local: localItems)
          .where(
            (listing) =>
                matchesSearchParams(listing, params, hasPremium: hasPremium),
          )
          .toList(growable: false);
      final fallbackExamples = kExampleListings
          .where(
            (listing) =>
                matchesSearchParams(listing, params, hasPremium: hasPremium),
          )
          .toList(growable: false);
      final effectiveItems = merged.isNotEmpty ? merged : fallbackExamples;

      state = state.copyWith(
        items: effectiveItems,
        loading: false,
        clearError: true,
      );
    } on AppException catch (error) {
      final localItems = _read
          .read(locallyCreatedHostListingsProvider)
          .where(
            (listing) =>
                matchesSearchParams(listing, params, hasPremium: hasPremium),
          )
          .toList(growable: false);
      final fallbackExamples = kExampleListings
          .where(
            (listing) =>
                matchesSearchParams(listing, params, hasPremium: hasPremium),
          )
          .toList(growable: false);
      if (localItems.isNotEmpty) {
        state = state.copyWith(
          items: localItems,
          loading: false,
          clearError: true,
        );
      } else if (fallbackExamples.isNotEmpty) {
        state = state.copyWith(
          items: fallbackExamples,
          loading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(loading: false, errorMessage: error.message);
      }
    } catch (_) {
      final localItems = _read
          .read(locallyCreatedHostListingsProvider)
          .where(
            (listing) =>
                matchesSearchParams(listing, params, hasPremium: hasPremium),
          )
          .toList(growable: false);
      final fallbackExamples = kExampleListings
          .where(
            (listing) =>
                matchesSearchParams(listing, params, hasPremium: hasPremium),
          )
          .toList(growable: false);
      if (localItems.isNotEmpty) {
        state = state.copyWith(
          items: localItems,
          loading: false,
          clearError: true,
        );
      } else if (fallbackExamples.isNotEmpty) {
        state = state.copyWith(
          items: fallbackExamples,
          loading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          loading: false,
          errorMessage: 'Unable to search listings right now.',
        );
      }
    }
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
      return SearchController(ref);
    });
