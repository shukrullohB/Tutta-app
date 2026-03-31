import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/listing.dart';

final listingsProvider = StateProvider<AsyncValue<List<Listing>>>((ref) {
  return const AsyncValue.data(<Listing>[]);
});
