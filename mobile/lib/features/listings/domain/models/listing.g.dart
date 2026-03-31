// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ListingImpl _$$ListingImplFromJson(Map<String, dynamic> json) =>
    _$ListingImpl(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      district: json['district'] as String,
      type: $enumDecode(_$ListingTypeEnumMap, json['type']),
      maxGuests: (json['maxGuests'] as num).toInt(),
      minDays: (json['minDays'] as num).toInt(),
      maxDays: (json['maxDays'] as num).toInt(),
      nightlyPriceUzs: (json['nightlyPriceUzs'] as num?)?.toInt(),
      isActive: json['isActive'] as bool,
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$ListingAmenityEnumMap, e))
              .toList() ??
          const <ListingAmenity>[],
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      description: json['description'] as String?,
      landmark: json['landmark'] as String?,
      metro: json['metro'] as String?,
    );

Map<String, dynamic> _$$ListingImplToJson(_$ListingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hostId': instance.hostId,
      'title': instance.title,
      'city': instance.city,
      'district': instance.district,
      'type': _$ListingTypeEnumMap[instance.type]!,
      'maxGuests': instance.maxGuests,
      'minDays': instance.minDays,
      'maxDays': instance.maxDays,
      'nightlyPriceUzs': instance.nightlyPriceUzs,
      'isActive': instance.isActive,
      'amenities': instance.amenities
          .map((e) => _$ListingAmenityEnumMap[e]!)
          .toList(),
      'imageUrls': instance.imageUrls,
      'description': instance.description,
      'landmark': instance.landmark,
      'metro': instance.metro,
    };

const _$ListingTypeEnumMap = {
  ListingType.apartment: 'apartment',
  ListingType.room: 'room',
  ListingType.homePart: 'homePart',
  ListingType.freeStay: 'freeStay',
};

const _$ListingAmenityEnumMap = {
  ListingAmenity.wifi: 'wifi',
  ListingAmenity.airConditioner: 'airConditioner',
  ListingAmenity.kitchen: 'kitchen',
  ListingAmenity.washingMachine: 'washingMachine',
  ListingAmenity.parking: 'parking',
  ListingAmenity.privateBathroom: 'privateBathroom',
  ListingAmenity.kidsAllowed: 'kidsAllowed',
  ListingAmenity.petsAllowed: 'petsAllowed',
  ListingAmenity.womenOnly: 'womenOnly',
  ListingAmenity.menOnly: 'menOnly',
  ListingAmenity.hostLivesTogether: 'hostLivesTogether',
  ListingAmenity.instantConfirm: 'instantConfirm',
};
