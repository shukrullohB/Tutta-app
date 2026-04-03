import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/models/create_listing_input.dart';
import '../domain/models/listing.dart';
import 'search_controller.dart';

class CreateListingController extends StateNotifier<AsyncValue<void>> {
  CreateListingController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  Future<Listing> create(CreateListingInput input) async {
    state = const AsyncValue.loading();

    try {
      final created = await _read
          .read(listingsRepositoryProvider)
          .createListing(input);
      final canonicalListing = await _loadCanonicalListing(created);
      _upsertLocalListing(canonicalListing);
      _setPostMutationSyncState(
        listing: canonicalListing,
        hadSelectedImages: input.imageFiles.isNotEmpty,
      );
      _read.invalidate(hostOwnedListingsProvider);
      _read.invalidate(searchControllerProvider);
      _refreshAfterMutation(
        canonicalListing.id,
        fallbackListing: canonicalListing,
        keepWarning: input.imageFiles.isNotEmpty &&
            canonicalListing.imageUrls.isEmpty,
      );
      state = const AsyncValue.data(null);
      return canonicalListing;
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final wrapped = AppException(error.toString());
      state = AsyncValue.error(wrapped, stackTrace);
      throw wrapped;
    }
  }

  Future<Listing> update({
    required String listingId,
    required CreateListingInput input,
  }) async {
    state = const AsyncValue.loading();

    try {
      final updated = await _read
          .read(listingsRepositoryProvider)
          .updateListing(listingId: listingId, input: input);
      final canonicalListing = await _loadCanonicalListing(updated);
      _upsertLocalListing(canonicalListing);
      _setPostMutationSyncState(
        listing: canonicalListing,
        hadSelectedImages: input.imageFiles.isNotEmpty,
      );
      _read.invalidate(hostOwnedListingsProvider);
      _read.invalidate(searchControllerProvider);
      _refreshAfterMutation(
        canonicalListing.id,
        fallbackListing: canonicalListing,
        keepWarning: input.imageFiles.isNotEmpty &&
            canonicalListing.imageUrls.isEmpty,
      );
      state = const AsyncValue.data(null);
      return canonicalListing;
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final wrapped = AppException(error.toString());
      state = AsyncValue.error(wrapped, stackTrace);
      throw wrapped;
    }
  }

  Future<Listing> _loadCanonicalListing(Listing initialListing) async {
    final listingId = initialListing.id.trim();
    if (listingId.isEmpty) {
      throw const AppException(
        'The server returned an invalid listing id.',
      );
    }

    final canonicalListing = await _read
        .read(listingsRepositoryProvider)
        .getById(listingId);

    final resolvedListing = canonicalListing != null &&
            canonicalListing.imageUrls.isEmpty &&
            initialListing.imageUrls.isNotEmpty
        ? canonicalListing.copyWith(imageUrls: initialListing.imageUrls)
        : canonicalListing;

    if (!_isUsableListing(resolvedListing)) {
      throw const AppException(
        'The server saved the listing, but returned incomplete listing data.',
      );
    }

    return resolvedListing!;
  }

  void _upsertLocalListing(Listing listing) {
    final current = _read.read(locallyCreatedHostListingsProvider);
    final merged = mergeCreatedListings(
      remote: <Listing>[listing],
      local: current,
    );
    _read.read(locallyCreatedHostListingsProvider.notifier).state = merged;
  }

  bool _isUsableListing(Listing? listing) {
    if (listing == null) {
      return false;
    }
    return listing.id.trim().isNotEmpty &&
        listing.title.trim().isNotEmpty &&
        listing.city.trim().isNotEmpty &&
        listing.district.trim().isNotEmpty;
  }

  void _setPostMutationSyncState({
    required Listing listing,
    required bool hadSelectedImages,
  }) {
    if (hadSelectedImages && listing.imageUrls.isEmpty) {
      _read.read(hostListingsSyncInfoProvider.notifier).state =
          const HostListingsSyncInfo.warning(
        'Listing was saved, but the selected photos did not appear yet. Open Edit to upload them again.',
      );
      return;
    }
    _read.read(hostListingsSyncInfoProvider.notifier).state =
        const HostListingsSyncInfo.syncing();
  }

  Future<void> _refreshAfterMutation(
    String listingId, {
    required Listing fallbackListing,
    required bool keepWarning,
  }) async {
    final repository = _read.read(listingsRepositoryProvider);
    try {
      final confirmedListings = await repository.getMine(includeInactive: true);
      final canonicalItems = confirmedListings
          .where(_isUsableListing)
          .toList(growable: false);
      final hasListing = canonicalItems.any((item) => item.id == listingId);
      final currentLocal = _read.read(locallyCreatedHostListingsProvider);
      if (hasListing) {
        _read
            .read(locallyCreatedHostListingsProvider.notifier)
            .state = mergeCreatedListings(
          remote: canonicalItems,
          local: currentLocal,
        );
        if (!keepWarning) {
          _read.read(hostListingsSyncInfoProvider.notifier).state =
              const HostListingsSyncInfo.ok();
        }
        _read.invalidate(hostOwnedListingsProvider);
        _read.invalidate(searchControllerProvider);
        return;
      }

      final confirmedListing = await repository.getById(listingId);
      final currentUserId = _read
          .read(authControllerProvider)
          .valueOrNull
          ?.user
          ?.id;
      if (_isUsableListing(confirmedListing) &&
          (currentUserId == null || confirmedListing!.hostId == currentUserId)) {
        _read
            .read(locallyCreatedHostListingsProvider.notifier)
            .state = mergeCreatedListings(
          remote: <Listing>[confirmedListing!],
          local: currentLocal,
        );
      }
      _read
          .read(hostListingsSyncInfoProvider.notifier)
          .state = HostListingsSyncInfo.warning(
        keepWarning
            ? 'Listing was saved. My listings refresh is still catching up, and photos may still need another upload.'
            : 'Listing was saved. My listings refresh is still catching up.',
      );
      _read.invalidate(hostOwnedListingsProvider);
      _read.invalidate(searchControllerProvider);
    } on AppException catch (error) {
      _upsertLocalListing(fallbackListing);
      _read.read(hostListingsSyncInfoProvider.notifier).state =
          HostListingsSyncInfo.warning(
        keepWarning
            ? 'Listing was saved, but photos may still need another upload. ${error.message}'
            : error.message,
      );
      _read.invalidate(hostOwnedListingsProvider);
      _read.invalidate(searchControllerProvider);
    } catch (error) {
      _upsertLocalListing(fallbackListing);
      _read.read(hostListingsSyncInfoProvider.notifier).state =
          HostListingsSyncInfo.warning(
        keepWarning
            ? 'Listing was saved, but photos may still need another upload. $error'
            : error.toString(),
      );
      _read.invalidate(hostOwnedListingsProvider);
      _read.invalidate(searchControllerProvider);
    }
  }
}

final createListingControllerProvider =
    StateNotifierProvider<CreateListingController, AsyncValue<void>>((ref) {
      return CreateListingController(ref);
    });
