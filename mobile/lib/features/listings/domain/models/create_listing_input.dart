import 'listing.dart';

class CreateListingInput {
  const CreateListingInput({
    required this.title,
    required this.description,
    required this.city,
    required this.district,
    required this.type,
    required this.maxGuests,
    required this.minDays,
    required this.maxDays,
    required this.showPhone,
    this.landmark,
    this.metro,
    this.nightlyPriceUzs,
    this.freeStayProfile = const <String, dynamic>{},
  });

  final String title;
  final String description;
  final String city;
  final String district;
  final String? landmark;
  final String? metro;
  final ListingType type;
  final int? nightlyPriceUzs;
  final int maxGuests;
  final int minDays;
  final int maxDays;
  final bool showPhone;
  final Map<String, dynamic> freeStayProfile;
}
