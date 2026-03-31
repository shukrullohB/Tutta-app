// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Booking _$BookingFromJson(Map<String, dynamic> json) {
  return _Booking.fromJson(json);
}

/// @nodoc
mixin _$Booking {
  String get id => throw _privateConstructorUsedError;
  String get listingId => throw _privateConstructorUsedError;
  String get guestUserId => throw _privateConstructorUsedError;
  String get hostUserId => throw _privateConstructorUsedError;
  DateTime get checkInDate => throw _privateConstructorUsedError;
  DateTime get checkOutDate => throw _privateConstructorUsedError;
  BookingStatus get status => throw _privateConstructorUsedError;
  bool get paymentRequired => throw _privateConstructorUsedError;
  bool get isPaid => throw _privateConstructorUsedError;
  PaymentStatus? get paymentStatus => throw _privateConstructorUsedError;
  int get totalPriceUzs => throw _privateConstructorUsedError;
  int get guestsCount => throw _privateConstructorUsedError;
  bool get isReviewAllowed => throw _privateConstructorUsedError;

  /// Serializes this Booking to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingCopyWith<Booking> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingCopyWith<$Res> {
  factory $BookingCopyWith(Booking value, $Res Function(Booking) then) =
      _$BookingCopyWithImpl<$Res, Booking>;
  @useResult
  $Res call({
    String id,
    String listingId,
    String guestUserId,
    String hostUserId,
    DateTime checkInDate,
    DateTime checkOutDate,
    BookingStatus status,
    bool paymentRequired,
    bool isPaid,
    PaymentStatus? paymentStatus,
    int totalPriceUzs,
    int guestsCount,
    bool isReviewAllowed,
  });
}

/// @nodoc
class _$BookingCopyWithImpl<$Res, $Val extends Booking>
    implements $BookingCopyWith<$Res> {
  _$BookingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listingId = null,
    Object? guestUserId = null,
    Object? hostUserId = null,
    Object? checkInDate = null,
    Object? checkOutDate = null,
    Object? status = null,
    Object? paymentRequired = null,
    Object? isPaid = null,
    Object? paymentStatus = freezed,
    Object? totalPriceUzs = null,
    Object? guestsCount = null,
    Object? isReviewAllowed = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            listingId: null == listingId
                ? _value.listingId
                : listingId // ignore: cast_nullable_to_non_nullable
                      as String,
            guestUserId: null == guestUserId
                ? _value.guestUserId
                : guestUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            hostUserId: null == hostUserId
                ? _value.hostUserId
                : hostUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            checkInDate: null == checkInDate
                ? _value.checkInDate
                : checkInDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            checkOutDate: null == checkOutDate
                ? _value.checkOutDate
                : checkOutDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as BookingStatus,
            paymentRequired: null == paymentRequired
                ? _value.paymentRequired
                : paymentRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPaid: null == isPaid
                ? _value.isPaid
                : isPaid // ignore: cast_nullable_to_non_nullable
                      as bool,
            paymentStatus: freezed == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as PaymentStatus?,
            totalPriceUzs: null == totalPriceUzs
                ? _value.totalPriceUzs
                : totalPriceUzs // ignore: cast_nullable_to_non_nullable
                      as int,
            guestsCount: null == guestsCount
                ? _value.guestsCount
                : guestsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isReviewAllowed: null == isReviewAllowed
                ? _value.isReviewAllowed
                : isReviewAllowed // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookingImplCopyWith<$Res> implements $BookingCopyWith<$Res> {
  factory _$$BookingImplCopyWith(
    _$BookingImpl value,
    $Res Function(_$BookingImpl) then,
  ) = __$$BookingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String listingId,
    String guestUserId,
    String hostUserId,
    DateTime checkInDate,
    DateTime checkOutDate,
    BookingStatus status,
    bool paymentRequired,
    bool isPaid,
    PaymentStatus? paymentStatus,
    int totalPriceUzs,
    int guestsCount,
    bool isReviewAllowed,
  });
}

/// @nodoc
class __$$BookingImplCopyWithImpl<$Res>
    extends _$BookingCopyWithImpl<$Res, _$BookingImpl>
    implements _$$BookingImplCopyWith<$Res> {
  __$$BookingImplCopyWithImpl(
    _$BookingImpl _value,
    $Res Function(_$BookingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listingId = null,
    Object? guestUserId = null,
    Object? hostUserId = null,
    Object? checkInDate = null,
    Object? checkOutDate = null,
    Object? status = null,
    Object? paymentRequired = null,
    Object? isPaid = null,
    Object? paymentStatus = freezed,
    Object? totalPriceUzs = null,
    Object? guestsCount = null,
    Object? isReviewAllowed = null,
  }) {
    return _then(
      _$BookingImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        listingId: null == listingId
            ? _value.listingId
            : listingId // ignore: cast_nullable_to_non_nullable
                  as String,
        guestUserId: null == guestUserId
            ? _value.guestUserId
            : guestUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        hostUserId: null == hostUserId
            ? _value.hostUserId
            : hostUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        checkInDate: null == checkInDate
            ? _value.checkInDate
            : checkInDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        checkOutDate: null == checkOutDate
            ? _value.checkOutDate
            : checkOutDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as BookingStatus,
        paymentRequired: null == paymentRequired
            ? _value.paymentRequired
            : paymentRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPaid: null == isPaid
            ? _value.isPaid
            : isPaid // ignore: cast_nullable_to_non_nullable
                  as bool,
        paymentStatus: freezed == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as PaymentStatus?,
        totalPriceUzs: null == totalPriceUzs
            ? _value.totalPriceUzs
            : totalPriceUzs // ignore: cast_nullable_to_non_nullable
                  as int,
        guestsCount: null == guestsCount
            ? _value.guestsCount
            : guestsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isReviewAllowed: null == isReviewAllowed
            ? _value.isReviewAllowed
            : isReviewAllowed // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingImpl implements _Booking {
  const _$BookingImpl({
    required this.id,
    required this.listingId,
    required this.guestUserId,
    required this.hostUserId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.paymentRequired,
    required this.isPaid,
    this.paymentStatus,
    required this.totalPriceUzs,
    required this.guestsCount,
    required this.isReviewAllowed,
  });

  factory _$BookingImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingImplFromJson(json);

  @override
  final String id;
  @override
  final String listingId;
  @override
  final String guestUserId;
  @override
  final String hostUserId;
  @override
  final DateTime checkInDate;
  @override
  final DateTime checkOutDate;
  @override
  final BookingStatus status;
  @override
  final bool paymentRequired;
  @override
  final bool isPaid;
  @override
  final PaymentStatus? paymentStatus;
  @override
  final int totalPriceUzs;
  @override
  final int guestsCount;
  @override
  final bool isReviewAllowed;

  @override
  String toString() {
    return 'Booking(id: $id, listingId: $listingId, guestUserId: $guestUserId, hostUserId: $hostUserId, checkInDate: $checkInDate, checkOutDate: $checkOutDate, status: $status, paymentRequired: $paymentRequired, isPaid: $isPaid, paymentStatus: $paymentStatus, totalPriceUzs: $totalPriceUzs, guestsCount: $guestsCount, isReviewAllowed: $isReviewAllowed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.listingId, listingId) ||
                other.listingId == listingId) &&
            (identical(other.guestUserId, guestUserId) ||
                other.guestUserId == guestUserId) &&
            (identical(other.hostUserId, hostUserId) ||
                other.hostUserId == hostUserId) &&
            (identical(other.checkInDate, checkInDate) ||
                other.checkInDate == checkInDate) &&
            (identical(other.checkOutDate, checkOutDate) ||
                other.checkOutDate == checkOutDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.paymentRequired, paymentRequired) ||
                other.paymentRequired == paymentRequired) &&
            (identical(other.isPaid, isPaid) || other.isPaid == isPaid) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.totalPriceUzs, totalPriceUzs) ||
                other.totalPriceUzs == totalPriceUzs) &&
            (identical(other.guestsCount, guestsCount) ||
                other.guestsCount == guestsCount) &&
            (identical(other.isReviewAllowed, isReviewAllowed) ||
                other.isReviewAllowed == isReviewAllowed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    listingId,
    guestUserId,
    hostUserId,
    checkInDate,
    checkOutDate,
    status,
    paymentRequired,
    isPaid,
    paymentStatus,
    totalPriceUzs,
    guestsCount,
    isReviewAllowed,
  );

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingImplCopyWith<_$BookingImpl> get copyWith =>
      __$$BookingImplCopyWithImpl<_$BookingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingImplToJson(this);
  }
}

abstract class _Booking implements Booking {
  const factory _Booking({
    required final String id,
    required final String listingId,
    required final String guestUserId,
    required final String hostUserId,
    required final DateTime checkInDate,
    required final DateTime checkOutDate,
    required final BookingStatus status,
    required final bool paymentRequired,
    required final bool isPaid,
    final PaymentStatus? paymentStatus,
    required final int totalPriceUzs,
    required final int guestsCount,
    required final bool isReviewAllowed,
  }) = _$BookingImpl;

  factory _Booking.fromJson(Map<String, dynamic> json) = _$BookingImpl.fromJson;

  @override
  String get id;
  @override
  String get listingId;
  @override
  String get guestUserId;
  @override
  String get hostUserId;
  @override
  DateTime get checkInDate;
  @override
  DateTime get checkOutDate;
  @override
  BookingStatus get status;
  @override
  bool get paymentRequired;
  @override
  bool get isPaid;
  @override
  PaymentStatus? get paymentStatus;
  @override
  int get totalPriceUzs;
  @override
  int get guestsCount;
  @override
  bool get isReviewAllowed;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingImplCopyWith<_$BookingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
