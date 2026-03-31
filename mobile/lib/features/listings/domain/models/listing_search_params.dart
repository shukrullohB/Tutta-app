class ListingSearchParams {
  const ListingSearchParams({
    required this.city,
    required this.district,
    required this.guests,
    required this.includeFreeStay,
  });

  final String city;
  final String district;
  final int guests;
  final bool includeFreeStay;
}
