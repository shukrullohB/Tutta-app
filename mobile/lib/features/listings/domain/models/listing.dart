import 'package:freezed_annotation/freezed_annotation.dart';

part 'listing.freezed.dart';
part 'listing.g.dart';

enum ListingType { apartment, room, homePart, freeStay }

enum ListingAmenity {
  wifi,
  airConditioner,
  kitchen,
  washingMachine,
  parking,
  privateBathroom,
  kidsAllowed,
  petsAllowed,
  womenOnly,
  menOnly,
  hostLivesTogether,
  instantConfirm,
}

@freezed
class Listing with _$Listing {
  const factory Listing({
    required String id,
    required String hostId,
    required String title,
    required String city,
    required String district,
    required ListingType type,
    required int maxGuests,
    required int minDays,
    required int maxDays,
    required int? nightlyPriceUzs,
    required bool isActive,
    @Default(<ListingAmenity>[]) List<ListingAmenity> amenities,
    @Default(<String>[]) List<String> imageUrls,
    String? description,
    String? landmark,
    String? metro,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) =>
      _$ListingFromJson(json);
}
