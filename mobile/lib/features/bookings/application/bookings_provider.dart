import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/booking.dart';

final bookingsProvider = StateProvider<AsyncValue<List<Booking>>>((ref) {
  return const AsyncValue.data(<Booking>[]);
});
