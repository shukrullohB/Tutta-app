import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/models/create_listing_input.dart';
import '../domain/models/listing.dart';
import 'search_controller.dart';

class CreateListingController extends StateNotifier<AsyncValue<void>> {
  CreateListingController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  Future<Listing> create(CreateListingInput input) async {
    state = const AsyncValue.loading();

    try {
      final listing = await _read.read(listingsRepositoryProvider).createListing(input);
      state = const AsyncValue.data(null);
      return listing;
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
      final listing = await _read.read(listingsRepositoryProvider).updateListing(
            listingId: listingId,
            input: input,
          );
      state = const AsyncValue.data(null);
      return listing;
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final wrapped = AppException(error.toString());
      state = AsyncValue.error(wrapped, stackTrace);
      throw wrapped;
    }
  }
}

final createListingControllerProvider =
    StateNotifierProvider<CreateListingController, AsyncValue<void>>((ref) {
      return CreateListingController(ref);
    });
