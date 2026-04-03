import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';

final favoritesIdsProvider =
    StateNotifierProvider<FavoritesController, Set<String>>((ref) {
  return FavoritesController(ref);
});

class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController(this._ref) : super(<String>{}) {
    _restore();
  }

  final Ref _ref;
  static const _storageKey = 'favorites_listing_ids';

  bool isFavorite(String listingId) => state.contains(listingId);

  void toggle(String listingId) {
    final next = <String>{...state};
    if (next.contains(listingId)) {
      next.remove(listingId);
    } else {
      next.add(listingId);
    }
    state = next;
    _persist();
  }

  Future<void> _restore() async {
    try {
      final raw = await _ref.read(secureStorageServiceProvider).readString(
            _storageKey,
          );
      if (raw == null || raw.isEmpty) {
        return;
      }
      final parsed = jsonDecode(raw);
      if (parsed is List) {
        state = parsed
            .whereType<String>()
            .where((id) => id.trim().isNotEmpty)
            .toSet();
      }
    } catch (_) {
      // Ignore corrupted local payload and continue with empty favorites.
    }
  }

  Future<void> _persist() async {
    await _ref.read(secureStorageServiceProvider).writeString(
          key: _storageKey,
          value: jsonEncode(state.toList(growable: false)),
        );
  }
}
