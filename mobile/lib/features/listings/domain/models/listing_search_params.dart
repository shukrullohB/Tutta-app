import 'listing.dart';

class ListingSearchParams {
  const ListingSearchParams({
    required this.city,
    required this.district,
    required this.guests,
    required this.includeFreeStay,
    this.types = const <ListingType>[],
    this.amenities = const <ListingAmenity>[],
  });

  final String city;
  final String district;
  final int guests;
  final bool includeFreeStay;
  final List<ListingType> types;
  final List<ListingAmenity> amenities;
}
