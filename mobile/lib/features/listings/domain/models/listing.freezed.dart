// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Listing _$ListingFromJson(Map<String, dynamic> json) {
  return _Listing.fromJson(json);
}

/// @nodoc
mixin _$Listing {
  String get id => throw _privateConstructorUsedError;
  String get hostId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  ListingType get type => throw _privateConstructorUsedError;
  int get maxGuests => throw _privateConstructorUsedError;
  int get minDays => throw _privateConstructorUsedError;
  int get maxDays => throw _privateConstructorUsedError;
  int? get nightlyPriceUzs => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  List<ListingAmenity> get amenities => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get landmark => throw _privateConstructorUsedError;
  String? get metro => throw _privateConstructorUsedError;

  /// Serializes this Listing to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ListingCopyWith<Listing> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ListingCopyWith<$Res> {
  factory $ListingCopyWith(Listing value, $Res Function(Listing) then) =
      _$ListingCopyWithImpl<$Res, Listing>;
  @useResult
  $Res call({
    String id,
    String hostId,
    String title,
    String city,
    String district,
    ListingType type,
    int maxGuests,
    int minDays,
    int maxDays,
    int? nightlyPriceUzs,
    bool isActive,
    List<ListingAmenity> amenities,
    List<String> imageUrls,
    String? description,
    String? landmark,
    String? metro,
  });
}

/// @nodoc
class _$ListingCopyWithImpl<$Res, $Val extends Listing>
    implements $ListingCopyWith<$Res> {
  _$ListingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hostId = null,
    Object? title = null,
    Object? city = null,
    Object? district = null,
    Object? type = null,
    Object? maxGuests = null,
    Object? minDays = null,
    Object? maxDays = null,
    Object? nightlyPriceUzs = freezed,
    Object? isActive = null,
    Object? amenities = null,
    Object? imageUrls = null,
    Object? description = freezed,
    Object? landmark = freezed,
    Object? metro = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            hostId: null == hostId
                ? _value.hostId
                : hostId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            district: null == district
                ? _value.district
                : district // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ListingType,
            maxGuests: null == maxGuests
                ? _value.maxGuests
                : maxGuests // ignore: cast_nullable_to_non_nullable
                      as int,
            minDays: null == minDays
                ? _value.minDays
                : minDays // ignore: cast_nullable_to_non_nullable
                      as int,
            maxDays: null == maxDays
                ? _value.maxDays
                : maxDays // ignore: cast_nullable_to_non_nullable
                      as int,
            nightlyPriceUzs: freezed == nightlyPriceUzs
                ? _value.nightlyPriceUzs
                : nightlyPriceUzs // ignore: cast_nullable_to_non_nullable
                      as int?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            amenities: null == amenities
                ? _value.amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                      as List<ListingAmenity>,
            imageUrls: null == imageUrls
                ? _value.imageUrls
                : imageUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            landmark: freezed == landmark
                ? _value.landmark
                : landmark // ignore: cast_nullable_to_non_nullable
                      as String?,
            metro: freezed == metro
                ? _value.metro
                : metro // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ListingImplCopyWith<$Res> implements $ListingCopyWith<$Res> {
  factory _$$ListingImplCopyWith(
    _$ListingImpl value,
    $Res Function(_$ListingImpl) then,
  ) = __$$ListingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String hostId,
    String title,
    String city,
    String district,
    ListingType type,
    int maxGuests,
    int minDays,
    int maxDays,
    int? nightlyPriceUzs,
    bool isActive,
    List<ListingAmenity> amenities,
    List<String> imageUrls,
    String? description,
    String? landmark,
    String? metro,
  });
}

/// @nodoc
class __$$ListingImplCopyWithImpl<$Res>
    extends _$ListingCopyWithImpl<$Res, _$ListingImpl>
    implements _$$ListingImplCopyWith<$Res> {
  __$$ListingImplCopyWithImpl(
    _$ListingImpl _value,
    $Res Function(_$ListingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hostId = null,
    Object? title = null,
    Object? city = null,
    Object? district = null,
    Object? type = null,
    Object? maxGuests = null,
    Object? minDays = null,
    Object? maxDays = null,
    Object? nightlyPriceUzs = freezed,
    Object? isActive = null,
    Object? amenities = null,
    Object? imageUrls = null,
    Object? description = freezed,
    Object? landmark = freezed,
    Object? metro = freezed,
  }) {
    return _then(
      _$ListingImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        hostId: null == hostId
            ? _value.hostId
            : hostId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        district: null == district
            ? _value.district
            : district // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ListingType,
        maxGuests: null == maxGuests
            ? _value.maxGuests
            : maxGuests // ignore: cast_nullable_to_non_nullable
                  as int,
        minDays: null == minDays
            ? _value.minDays
            : minDays // ignore: cast_nullable_to_non_nullable
                  as int,
        maxDays: null == maxDays
            ? _value.maxDays
            : maxDays // ignore: cast_nullable_to_non_nullable
                  as int,
        nightlyPriceUzs: freezed == nightlyPriceUzs
            ? _value.nightlyPriceUzs
            : nightlyPriceUzs // ignore: cast_nullable_to_non_nullable
                  as int?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        amenities: null == amenities
            ? _value._amenities
            : amenities // ignore: cast_nullable_to_non_nullable
                  as List<ListingAmenity>,
        imageUrls: null == imageUrls
            ? _value._imageUrls
            : imageUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        landmark: freezed == landmark
            ? _value.landmark
            : landmark // ignore: cast_nullable_to_non_nullable
                  as String?,
        metro: freezed == metro
            ? _value.metro
            : metro // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ListingImpl implements _Listing {
  const _$ListingImpl({
    required this.id,
    required this.hostId,
    required this.title,
    required this.city,
    required this.district,
    required this.type,
    required this.maxGuests,
    required this.minDays,
    required this.maxDays,
    required this.nightlyPriceUzs,
    required this.isActive,
    final List<ListingAmenity> amenities = const <ListingAmenity>[],
    final List<String> imageUrls = const <String>[],
    this.description,
    this.landmark,
    this.metro,
  }) : _amenities = amenities,
       _imageUrls = imageUrls;

  factory _$ListingImpl.fromJson(Map<String, dynamic> json) =>
      _$$ListingImplFromJson(json);

  @override
  final String id;
  @override
  final String hostId;
  @override
  final String title;
  @override
  final String city;
  @override
  final String district;
  @override
  final ListingType type;
  @override
  final int maxGuests;
  @override
  final int minDays;
  @override
  final int maxDays;
  @override
  final int? nightlyPriceUzs;
  @override
  final bool isActive;
  final List<ListingAmenity> _amenities;
  @override
  @JsonKey()
  List<ListingAmenity> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

  final List<String> _imageUrls;
  @override
  @JsonKey()
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  @override
  final String? description;
  @override
  final String? landmark;
  @override
  final String? metro;

  @override
  String toString() {
    return 'Listing(id: $id, hostId: $hostId, title: $title, city: $city, district: $district, type: $type, maxGuests: $maxGuests, minDays: $minDays, maxDays: $maxDays, nightlyPriceUzs: $nightlyPriceUzs, isActive: $isActive, amenities: $amenities, imageUrls: $imageUrls, description: $description, landmark: $landmark, metro: $metro)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.hostId, hostId) || other.hostId == hostId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.maxGuests, maxGuests) ||
                other.maxGuests == maxGuests) &&
            (identical(other.minDays, minDays) || other.minDays == minDays) &&
            (identical(other.maxDays, maxDays) || other.maxDays == maxDays) &&
            (identical(other.nightlyPriceUzs, nightlyPriceUzs) ||
                other.nightlyPriceUzs == nightlyPriceUzs) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ) &&
            const DeepCollectionEquality().equals(
              other._imageUrls,
              _imageUrls,
            ) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.landmark, landmark) ||
                other.landmark == landmark) &&
            (identical(other.metro, metro) || other.metro == metro));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    hostId,
    title,
    city,
    district,
    type,
    maxGuests,
    minDays,
    maxDays,
    nightlyPriceUzs,
    isActive,
    const DeepCollectionEquality().hash(_amenities),
    const DeepCollectionEquality().hash(_imageUrls),
    description,
    landmark,
    metro,
  );

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ListingImplCopyWith<_$ListingImpl> get copyWith =>
      __$$ListingImplCopyWithImpl<_$ListingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ListingImplToJson(this);
  }
}

abstract class _Listing implements Listing {
  const factory _Listing({
    required final String id,
    required final String hostId,
    required final String title,
    required final String city,
    required final String district,
    required final ListingType type,
    required final int maxGuests,
    required final int minDays,
    required final int maxDays,
    required final int? nightlyPriceUzs,
    required final bool isActive,
    final List<ListingAmenity> amenities,
    final List<String> imageUrls,
    final String? description,
    final String? landmark,
    final String? metro,
  }) = _$ListingImpl;

  factory _Listing.fromJson(Map<String, dynamic> json) = _$ListingImpl.fromJson;

  @override
  String get id;
  @override
  String get hostId;
  @override
  String get title;
  @override
  String get city;
  @override
  String get district;
  @override
  ListingType get type;
  @override
  int get maxGuests;
  @override
  int get minDays;
  @override
  int get maxDays;
  @override
  int? get nightlyPriceUzs;
  @override
  bool get isActive;
  @override
  List<ListingAmenity> get amenities;
  @override
  List<String> get imageUrls;
  @override
  String? get description;
  @override
  String? get landmark;
  @override
  String? get metro;

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ListingImplCopyWith<_$ListingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
